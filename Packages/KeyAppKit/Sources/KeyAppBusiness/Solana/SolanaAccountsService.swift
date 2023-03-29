//
//  SolanaAccountsManager.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.03.2023.
//

import Combine
import Foundation
import KeyAppKitCore
import SolanaPricesAPIs
import SolanaSwift

/// This manager class monitors solana accounts and their changing real time by using socket and 10 seconds updating
/// timer.
///
/// It also calculates ``amountInFiat`` by integrating with ``NewPriceService``.
public final class SolanaAccountsService: NSObject, AccountsService, ObservableObject {
    public typealias Account = SolanaAccount

    var subscriptions = [AnyCancellable]()

    let accounts: AsyncValue<[Account]>
//    let prices: AsyncValue<>

    @Published public var state: AsyncValueState<[Account]> = .init(value: [])

    public init(
        accountStorage: SolanaAccountStorage,
        solanaAPIClient: SolanaAPIClient,
        tokensService: SolanaTokensRepository,
        priceService: SolanaPriceService,
        accountObservableService: SolanaAccountsObservableService,
        fiat: String,
        errorObservable: any ErrorObserver
    ) {
        // Setup async value
        accounts = .init(initialItem: []) {
            guard let accountAddress = accountStorage.account?.publicKey.base58EncodedString else {
                return (nil, Error.authorityError)
            }

            var newAccounts: [Account] = []

            do {
                // Updating native account balance and get spl tokens
                let (balance, splAccounts) = try await(
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

                return (newAccounts, nil)
            } catch {
                return (nil, error)
            }
        }

        super.init()

        /// Updating price
        let prices = accounts
            .$state
            .filter { $0.status == .initializing || $0.status == .ready }
            .delay(for: 0.1, scheduler: RunLoop.main)
            .asyncMap { state in
                try? await errorObservable.run {
                    try await priceService.getPrices(
                        tokens: state.value.map(\.data.token),
                        fiat: fiat
                    )
                }
            }

        // Report error
        errorObservable
            .handleAsyncValue($state)
            .store(in: &subscriptions)

        // Emit data
        Publishers
            .CombineLatest(accounts.$state, prices)
            .map { state, prices in
                guard let prices else { return state }

                return state.apply { accounts in
                    var newAccounts = accounts

                    for index in newAccounts.indices {
                        let token = newAccounts[index].data.token
                        if let price = prices[token] {
                            // Convert to token
                            let value: Decimal?
                            if let priceValue = price?.value {
                                value = Decimal(floatLiteral: priceValue)
                            } else {
                                value = nil
                            }

                            newAccounts[index]
                                .price = .init(currencyCode: fiat.uppercased(), value: value, token: token)
                        }
                    }

                    return newAccounts
                }
            }
            .weakAssign(to: \.state, on: self)
            .store(in: &subscriptions)

        // Update every 10 seconds accounts and balance
        Timer
            .publish(every: 10, on: .main, in: .default)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in self?.accounts.fetch() })
            .store(in: &subscriptions)

        // Observe solana accounts
        $state
            .sink { state in
                for account in state.value {
                    guard let pubkey = account.data.pubkey else { continue }
                    Task {
                        try await accountObservableService.subscribeAccountNotification(account: pubkey)
                    }
                }
            }
            .store(in: &subscriptions)

        // Update solana accounts
        accountObservableService
            .allAccountsNotificcationsPublisher
            .sink { _ in
                Task { [weak self] in
                    try await self?.fetch()
                }
            }
            .store(in: &subscriptions)

        // First fetch
        Task.detached {
            try await self.fetch()
        }
    }

    /// Fetch new data from blockchain.
    public func fetch() async throws {
        try await accounts.fetch()?.value
    }
}

public extension Array where Element == SolanaAccountsService.Account {
    /// Helper method for quickly extraction native account.
    var nativeWallet: Element? {
        first(where: { $0.data.isNativeSOL })
    }

    var totalAmountInCurrentFiat: Double {
        reduce(0) { $0 + $1.amountInFiatDouble }
    }

    var isTotalBalanceEmpty: Bool {
        totalAmountInCurrentFiat == 0
    }
}

public extension SolanaAccountsService {
    enum Error: Swift.Error {
        case authorityError
    }
}
