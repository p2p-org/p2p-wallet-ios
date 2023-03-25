//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Combine
import Foundation
import KeyAppKitCore
import SolanaPricesAPIs
import Web3

public final class EthereumAccountsService: NSObject, AccountsService, ObservableObject {
    public typealias Account = EthereumAccount
    
    private var subscriptions = [AnyCancellable]()

    private let asyncValue: AsyncValue<[Account]>

    @Published public var state: AsyncValueState<[Account]> = .init(value: [])

    public init(
        address: String,
        web3: Web3,
        ethereumTokenRepository: EthereumTokensRepository,
        priceService: EthereumPriceService,
        fiat: String,
        errorObservable: any ErrorObserver
    ) {
        let address = try? EthereumAddress(hex: address, eip55: false)

        asyncValue = .init(initialItem: [], request: {
            guard let address else {
                return (nil, Error.invalidEthereumAddress)
            }

            do {
                // Fetch balance and token balances
                let (balance, wallet) = try await (
                    web3.eth.getBalance(address: address, block: .latest),
                    web3.eth.getTokenBalances(address: address)
                )

                var nativeAccount = Account(
                    address: address.hex(eip55: false),
                    token: .init(),
                    balance: balance.quantity,
                    price: nil
                )

                // Build token accounts
                let tokenBalances = wallet.tokenBalances

                // Build token accounts
                var resolvedTokenAccounts: [Account] = try await Self.resolveTokenAccounts(
                    address: address.hex(eip55: false),
                    balances: tokenBalances,
                    repository: ethereumTokenRepository
                )

                do {
                    // Fetch prices
                    let (etherumPrice, tokenPrices) = try await (
                        priceService.getEthereumPrice(fiat: fiat),
                        priceService.getPrices(tokens: resolvedTokenAccounts.map(\.token), fiat: fiat)
                    )

                    // Set price to native token
                    nativeAccount.price = etherumPrice

                    // Set price to tokens.
                    for index in resolvedTokenAccounts.indices {
                        let token = resolvedTokenAccounts[index].token
                        if let price = tokenPrices[token] {
                            resolvedTokenAccounts[index].price = price
                        }
                    }
                } catch {
                    return ([nativeAccount] + resolvedTokenAccounts, error)
                }

                return ([nativeAccount] + resolvedTokenAccounts, nil)
            } catch {
                return (nil, error)
            }
        })

        super.init()

        errorObservable
            .handleAsyncValue($state)
            .store(in: &subscriptions)

        asyncValue
            .$state
            .weakAssign(to: \.state, on: self)
            .store(in: &subscriptions)

        // Update every 30 seconds accounts and balance
        Timer
            .publish(every: 30, on: .main, in: .default)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in self?.asyncValue.fetch() })
            .store(in: &subscriptions)

        // First fetch
        Task.detached {
            try await self.fetch()
        }
    }

    /// Method resolve ethereum erc-20 token accounts.
    internal static func resolveTokenAccounts(
        address: String,
        balances: [EthereumTokenBalances.Balance],
        repository: EthereumTokensRepository
    ) async throws -> [Account] {
        try await withThrowingTaskGroup(of: (EthereumTokenBalances.Balance, EthereumToken).self) { group in
            for balance in balances {
                group.addTask {
                    (
                        balance,
                        try await repository.resolve(address: balance.contractAddress.hex(eip55: false))
                    )
                }
            }

            var result: [(EthereumTokenBalances.Balance, EthereumToken)] = []
            for try await item in group {
                result.append(item)
            }

            return result.map { item in
                Account(address: address, token: item.1, balance: item.0.tokenBalance ?? 0)
            }
        }
    }

    /// Fetch new data from blockchain.
    public func fetch() async throws {
        try await asyncValue.fetch()?.value
    }
}

extension EthereumAccountsService {
    enum Error: Swift.Error {
        case invalidEthereumAddress
    }
}

extension BigUInt {
    static func divide(_ lhs: BigUInt, _ rhs: BigUInt) -> Decimal {
        let (quotient, remainder) = lhs.quotientAndRemainder(dividingBy: rhs)
        return Decimal(string: String(quotient))! + Decimal(string: String(remainder))! / Decimal(string: String(rhs))!
    }
}
