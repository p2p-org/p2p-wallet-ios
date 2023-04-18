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

/// Provider for providing account from Ethereum network
final class EthereumAccountsProvider: NSObject, AccountsProvider, ObservableObject
{
    // MARK: - Properties

    private var subscriptions = [AnyCancellable]()

    private let accounts: AsyncValue<[EthereumAccount]>

    @Published var state: AsyncValueState<[EthereumAccount]> = .init(value: [])

    init(
        address: String,
        web3: Web3,
        ethereumTokenRepository: EthereumTokensRepository,
        priceService: EthereumPriceService,
        fiat: String,
        errorObservable: any ErrorObserver
    ) {
        let address = try? EthereumAddress(hex: address, eip55: false)

        accounts = .init(initialItem: [], request: {
            guard let address else {
                return (nil, EthereumAccountsProviderError.invalidEthereumAddress)
            }

            do {
                // Fetch balance and token balances
                let (balance, wallet) = try await(
                    web3.eth.getBalance(address: address, block: .latest),
                    web3.eth.getTokenBalances(address: address)
                )

                let nativeAccount = Account(
                    address: address.hex(eip55: false),
                    token: .init(),
                    balance: balance.quantity,
                    price: nil
                )

                // Build token accounts
                let tokenBalances = wallet.tokenBalances

                // Build token accounts
                let resolvedTokenAccounts: [Account] = try await Self.resolveTokenAccounts(
                    address: address.hex(eip55: false),
                    balances: tokenBalances,
                    repository: ethereumTokenRepository
                )

                return ([nativeAccount] + resolvedTokenAccounts, nil)
            } catch {
                return (nil, error)
            }
        })

        super.init()

        /// Updating price
        let prices = accounts
            .$state
            .filter { $0.status == .initializing || $0.status == .ready }
            .asyncMap { state in
                try? await errorObservable.run {
                    try await priceService.getPrices(
                        tokens: state.value.map(\.token),
                        fiat: fiat
                    )
                }
            }

        Publishers
            .CombineLatest(accounts.$state, prices)
            .map { state, prices in
                guard let prices else { return state }

                return state.apply { accounts in
                    var newAccounts = accounts

                    for index in newAccounts.indices {
                        let token = newAccounts[index].token
                        if let price = prices[token] {
                            newAccounts[index]
                                .price = .init(currencyCode: fiat.uppercased(), value: price.value, token: token)
                        }
                    }

                    return newAccounts
                }
            }
            .weakAssign(to: \.state, on: self)
            .store(in: &subscriptions)

        // Update every 30 seconds accounts and balance
        Timer
            .publish(every: 30, on: .main, in: .default)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in self?.accounts.fetch() })
            .store(in: &subscriptions)

        errorObservable
            .handleAsyncValue($state)
            .store(in: &subscriptions)

        // First fetch
        Task.detached {
            try await self.fetch()
        }
    }

    /// Method resolve ethereum erc-20 token accounts.
    static func resolveTokenAccounts(
        address: String,
        balances: [EthereumTokenBalances.Balance],
        repository: EthereumTokensRepository
    ) async throws -> [EthereumAccount] {
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
    func fetch() async throws {
        try await accounts.fetch()?.value
    }
}
