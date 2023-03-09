//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Combine
import Foundation
import KeyAppKitCore
import Web3

public final class EthereumAccountsService: NSObject, ObservableObject {
    private var subscriptions = [AnyCancellable]()

    private let asyncValue: AsyncValue<[Account]>

    @Published public var state: AsyncValueState<[Account]> = .init(value: [])

    public init(
        address: String,
        web3: Web3,
        ethereumTokenRepository: EthereumTokensRepository,
        priceService: PriceService,
        trackingList: [EthereumAddress],
        fiat: String
    ) {
        let address = try? EthereumAddress(hex: address, eip55: false)

        asyncValue = .init(initialItem: [], request: {
            guard let address else {
                throw Error.invalidEthereumAddress
            }

            // Fetch balance and token balances
            let (balance, wallet) = try await (
                web3.eth.getBalance(address: address, block: .latest),
                web3.eth.getTokenBalances(address: address)
            )

            var tokenBalances = wallet.tokenBalances

            // Filter token by tracking list
            if !trackingList.isEmpty {
                tokenBalances = tokenBalances.filter { balance in
                    trackingList.contains(balance.contractAddress)
                }
            }

            // Build token accounts
            let resolvedTokenAccounts: [Account] = try await Self.resolveTokenAccounts(
                balances: tokenBalances,
                repository: ethereumTokenRepository
            )

            return [Account(token: .init(), balance: balance.quantity)] + resolvedTokenAccounts
        })

        super.init()

        asyncValue
            .$state
            .weakAssign(to: \.state, on: self)
            .store(in: &subscriptions)

        // Update every 10 seconds accounts and balance
        Timer
            .publish(every: 10, on: .main, in: .default)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in self?.asyncValue.fetch() })
            .store(in: &subscriptions)

        // First fetch
        Task.detached {
            try await self.fetch()
        }
    }

    internal static func resolveTokenAccounts(
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
                Account(token: item.1, balance: item.0.tokenBalance ?? 0)
            }
        }
    }

    /// Fetch new data from blockchain.
    public func fetch() async throws {
        try await asyncValue.fetch()?.value
    }
}

extension EthereumAccountsService {
    public struct Account: Equatable {
        let token: EthereumToken
        let balance: BigUInt
    }

    enum Error: Swift.Error {
        case invalidEthereumAddress
    }
}
