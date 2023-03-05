//
//  SolanaAccountsManager.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.03.2023.
//

import Combine
import Foundation
import Resolver
import SolanaPricesAPIs
import SolanaSwift

class SolanaAccountsManager: NSObject, ObservableObject {
    private var subscriptions = [AnyCancellable]()

    private let asyncValue: AsyncValue<[Account]>

    @Published var state: AsynValueState<[Account]> = .init(item: [])

    init(
        accountStorage: SolanaAccountStorage = Resolver.resolve(),
        solanaAPIClient: SolanaAPIClient = Resolver.resolve(),
        tokensService: SolanaTokensRepository = Resolver.resolve(),
        priceService: NewPriceService = Resolver.resolve()
    ) {
        asyncValue = .init(initialItem: []) {
            guard let accountAddress = accountStorage.account?.publicKey.base58EncodedString else {
                throw Error.authorityError
            }

            var newAccounts: [Account] = []

            // Updating native account balance and get spl tokens
            let (balance, splAccounts) = try await (
                // TODO: Check commitment value! Previously was ``recent``
                solanaAPIClient.getBalance(account: accountAddress, commitment: "processed"),
                solanaAPIClient.getTokenWallets(account: accountAddress, tokensRepository: tokensService)
            )

            let solanaAccount = Account(
                data: Wallet.nativeSolana(
                    pubkey: accountAddress,
                    lamport: balance
                )
            )

            newAccounts = [solanaAccount] + splAccounts.map { Account(data: $0, price: nil) }

            // Updating balance
            let prices = try await priceService.getPrices(tokens: newAccounts.map(\.data.token))

            for index in newAccounts.indices {
                let token = newAccounts[index].data.token
                if let price = prices[token] {
                    newAccounts[index].price = price
                }
            }

            return newAccounts
        }

        super.init()

        // Emit data
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

    /// Fetch new data from blockchain.
    func fetch() async throws {
        try await asyncValue.fetch()?.value
    }
}

extension Array where Element == SolanaAccountsManager.Account {
    /// Helper method for quickly extraction native account.
    var nativeWallet: Element? {
        first(where: { $0.data.isNativeSOL })
    }

    var totalAmountInCurrentFiat: Double {
        reduce(0) { $0 + $1.amountInFiat }
    }

    var isTotalBalanceEmpty: Bool {
        totalAmountInCurrentFiat == 0
    }
}

extension SolanaAccountsManager {
    /// Solana account data structure.
    /// This class is combination of raw account data and additional application data.
    struct Account: Identifiable, Equatable {
        var id: String {
            data.pubkey ?? data.mintAddress
        }

        /// Data field
        let data: SolanaSwift.Wallet

        /// The fetched price at current moment of time.
        fileprivate(set) var price: CurrentPrice?

        /// Get current amount in fiat.
        var amountInFiat: Double {
            data.amount * price?.value
        }
    }

    enum Status {
        case initializing
        case updating
        case ready
    }

    enum Error: Swift.Error {
        case authorityError
    }
}
