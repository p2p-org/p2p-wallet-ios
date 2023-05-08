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
public final class SolanaAccountsService: NSObject, AccountsService {
    public typealias Account = SolanaAccount

    // MARK: - Properties

    public let realtimeService: RealtimeSolanaAccountService?

    var subscriptions = [AnyCancellable]()

    // MARK: - Source

    /// The stream of account by rpc call to node.
    let originStream: AsyncValue<[Account]>

    /// The final stream origin base on additional updating through socket.
    let realtimeStream: CurrentValueSubject<AsyncValueState<[Account]>, Never> = .init(.init(value: []))

    /// Requested token price base on final stream.
    let priceStream: CurrentValueSubject<[Token: CurrentPrice?], Never> = .init([:])

    // MARK: - Output

    public var outputSubject: CurrentValueSubject<AsyncValueState<[Account]>, Never> = .init(.init(value: []))

    public var statePublisher: AnyPublisher<AsyncValueState<[Account]>, Never> { outputSubject.eraseToAnyPublisher() }

    public var state: AsyncValueState<[Account]> { outputSubject.value }

    // MARK: - Init

    public init(
        accountStorage: SolanaAccountStorage,
        solanaAPIClient: SolanaAPIClient,
        tokensService: SolanaTokensRepository,
        priceService: SolanaPriceService,
        fiat: String,
        errorObservable: any ErrorObserver
    ) {
        // Setup async value
        originStream = .init(initialItem: []) {
            guard let accountAddress = accountStorage.account?.publicKey.base58EncodedString else {
                return (nil, Error.authorityError)
            }

            var newAccounts: [Account] = []

            do {
                // Updating native account balance and get spl tokens
                let (balance, splAccounts) = try await(
                    // TODO: Check commitment value! Previously was ``recent``
                    solanaAPIClient.getBalance(account: accountAddress, commitment: "confirmed"),
                    solanaAPIClient.getTokenWallets(
                        account: accountAddress,
                        tokensRepository: tokensService,
                        commitment: "confirmed"
                    )
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

        // Emit origin stream to final stream
        originStream
            .statePublisher
            .sink { [weak realtimeStream] state in
                realtimeStream?.send(state)
            }
            .store(in: &subscriptions)

        // Setup realtime service
        if let owner = accountStorage.account?.publicKey.base58EncodedString {
            realtimeService = RealtimeSolanaAccountServiceImpl(
                owner: owner,
                apiClient: solanaAPIClient,
                tokensService: tokensService,
                errorObserver: errorObservable
            )

            realtimeService?.connect()
        } else {
            realtimeService = nil
        }

        super.init()

        // Listen realtime service
        realtimeService?
            .update
            .sink { [weak self] account in
                guard let self else { return }

                var state = self.realtimeStream.value

                let matchIdx = state.value
                    .firstIndex {
                        $0.data.token.address == account.data.token.address
                    }

                if let matchIdx {
                    state.value[matchIdx] = account
                } else {
                    state.value.append(account)
                }

                self.realtimeStream.send(state)
            }
            .store(in: &subscriptions)

        /// Parallel price updating. We will show price later.
        realtimeStream
            .filter { $0.status == .initializing || $0.status == .ready }
            .debounce(for: .seconds(0.05), scheduler: RunLoop.main)
            .asyncMap { state in
                do {
                    return try await priceService.getPrices(
                        tokens: state.value.map(\.data.token),
                        fiat: fiat
                    )
                } catch {
                    errorObservable.handleError(error)
                    return [:]
                }
            }
            .sink { [weak self] price in
                self?.priceStream.send(price)
            }
            .store(in: &subscriptions)

        // Report error
        errorObservable
            .handleAsyncValue(originStream)
            .store(in: &subscriptions)

        // Emit data to output
        let accountsAggregator = SolanaAccountsAggregator()
        Publishers
            .CombineLatest(realtimeStream, priceStream)
            .map { state, prices in
                var state = state
                state.value = accountsAggregator.transform(input: (state.value, fiat, prices))
                return state
            }
            .sink { [weak outputSubject] state in
                outputSubject?.send(state)
            }
            .store(in: &subscriptions)

        // First fetch
        Task.detached {
            try await self.fetch()
        }
    }

    // MARK: - Methods

    /// Fetch new data from blockchain.
    public func fetch() async throws {
        try await originStream.fetch()?.value
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
