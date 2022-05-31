//
//  DerivableAccounts.ListViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/05/2021.
//

import BECollectionView
import Foundation
import Resolver
import RxConcurrency
import RxSwift
import SolanaSwift

protocol DerivableAccountsListViewModelType: BEListViewModelType {
    func cancelRequest()
    func reload()
    func setDerivablePath(_ derivablePath: DerivablePath)
}

extension DerivableAccounts {
    class ListViewModel: BEListViewModel<DerivableAccount> {
        // MARK: - Dependencies

        @Injected private var pricesFetcher: PricesFetcher
        @Injected private var solanaAPIClient: SolanaAPIClient

        // MARK: - Properties

        private let phrases: [String]
        var derivablePath: DerivablePath?
        let disposeBag = DisposeBag()

        fileprivate let cache = Cache()

        init(phrases: [String]) {
            self.phrases = phrases
            super.init(initialData: [])
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        override func createRequest() -> Single<[DerivableAccount]> {
            Single.async { [weak self] in
                guard let self = self else { throw SolanaError.unknown }
                let accounts = try await self.createDerivableAccounts()

                Task {
                    try? await(
                        self.fetchSOLPrice(),
                        self.fetchBalances(accounts: accounts.map(\.info.publicKey.base58EncodedString))
                    )
                }

                return accounts
            }
        }

        private func createDerivableAccounts() async throws -> [DerivableAccount] {
            let phrases = self.phrases
            guard let path = derivablePath else {
                throw SolanaError.unknown
            }
            return try await withThrowingTaskGroup(of: (Int, SolanaSwift.Account).self) { group in
                var accounts = [DerivableAccount]()

                for i in 0 ..< 5 {
                    group.addTask(priority: .userInitiated) {
                        (i, try await SolanaSwift.Account(
                            phrase: phrases,
                            network: Defaults.apiEndPoint.network,
                            derivablePath: .init(type: path.type, walletIndex: i)
                        ))
                    }
                }

                for try await(index, account) in group {
                    accounts.append(
                        .init(
                            info: account,
                            amount: await self.cache.balanceCache[account.publicKey.base58EncodedString],
                            price: await self.cache.solPriceCache,
                            isBlured: index > 2
                        )
                    )
                }

                return accounts
            }
        }

        private func fetchSOLPrice() async throws {
            if await cache.solPriceCache != nil { return }

            try Task.checkCancellation()

            let solPrice = try await pricesFetcher.getCurrentPrices(coins: ["SOL"], toFiat: Defaults.fiat.code)
                .map { $0.first?.value?.value ?? 0 }
                .value
            await cache.save(solPrice: solPrice)

            try Task.checkCancellation()

            if currentState == .loaded {
                let data = data.map { account -> DerivableAccount in
                    var account = account
                    account.price = solPrice
                    return account
                }
                overrideData(by: data)
            }
        }

        private func fetchBalances(accounts: [String]) async throws {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for account in accounts {
                    group.addTask {
                        try await self.fetchBalance(account: account)
                    }
                    try Task.checkCancellation()
                    for try await _ in group {}
                }
            }
        }

        private func fetchBalance(account: String) async throws {
            if await cache.balanceCache[account] != nil {
                return
            }

            try Task.checkCancellation()

            let amount = try await solanaAPIClient.getBalance(account: account, commitment: nil)
                .convertToBalance(decimals: 9)

            try Task.checkCancellation()
            await cache.save(account: account, amount: amount)

            try Task.checkCancellation()
            if currentState == .loaded {
                updateItem(
                    where: { $0.info.publicKey.base58EncodedString == account },
                    transform: { account in
                        var account = account
                        account.amount = amount
                        return account
                    }
                )
            }
        }
    }
}

extension DerivableAccounts.ListViewModel: DerivableAccountsListViewModelType {
    func setDerivablePath(_ derivablePath: DerivablePath) {
        self.derivablePath = derivablePath
    }
}
