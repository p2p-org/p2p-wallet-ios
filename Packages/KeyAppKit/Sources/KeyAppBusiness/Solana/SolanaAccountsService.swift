import Combine
import Foundation
import KeyAppKitCore
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
    let priceStream: CurrentValueSubject<[SomeToken: TokenPrice?], Never> = .init([:])

    // MARK: - Output

    public var outputSubject: CurrentValueSubject<AsyncValueState<[Account]>, Never> = .init(.init(value: []))

    public var statePublisher: AnyPublisher<AsyncValueState<[Account]>, Never> { outputSubject.eraseToAnyPublisher() }

    public var state: AsyncValueState<[Account]> { outputSubject.value }

    // MARK: - Init

    /// The service that return current user's accounts state and dynamically observe changing.
    /// - Parameters:
    ///   - accountStorage: Solana account storage that will return current user's wallet
    ///   - solanaAPIClient: Solana API Client
    ///   - tokensService: Token service to extract more information
    ///   - priceService: Map account with current price
    ///   - fiat: Fiat
    ///   - proxyConfiguration: Proxy configuration for socket
    ///   - errorObservable: Error observable service
    public init(
        accountStorage: SolanaAccountStorage,
        solanaAPIClient: SolanaAPIClient,
        tokensService: SolanaTokensService,
        priceService: PriceService,
        fiat: String,
        proxyConfiguration: ProxyConfiguration?,
        errorObservable: any ErrorObserver
    ) {
        // Setup async value
        originStream = .init(initialItem: []) { () async -> ([Account]?, Swift.Error?) in
            guard let accountAddress = accountStorage.account?.publicKey.base58EncodedString else {
                return (nil, Error.authorityError)
            }

            var newAccounts: [Account] = []

            do {
                // Updating native account balance and get spl tokens
                let (balance, (resolved, _)) = try await(
                    solanaAPIClient.getBalance(account: accountAddress, commitment: "confirmed"),
                    solanaAPIClient.getAccountBalances(
                        for: accountAddress,
                        tokensRepository: tokensService,
                        commitment: "confirmed"
                    )
                )

                let solanaAccount = Account(
                    address: accountAddress,
                    lamports: balance,
                    token: try await tokensService.nativeToken
                )

                newAccounts = [solanaAccount] + resolved
                    .map { accountBalance in
                        guard let pubkey = accountBalance.pubkey else {
                            return nil
                        }

                        return Account(
                            address: pubkey,
                            lamports: accountBalance.lamports ?? 0,
                            token: accountBalance.token
                        )
                    }
                    .compactMap { $0 }

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
                proxyConfiguration: proxyConfiguration,
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
                        $0.token.address == account.token.address
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
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .asyncMap { state -> [SomeToken: TokenPrice?] in
                do {
                    return try await priceService.getPrices(
                        tokens: state.value.map(\.token),
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
                state.value = accountsAggregator.transform(input: (state.value, prices))
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
        first(where: { $0.token.isNativeSOL })
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

    @available(*, deprecated, message: "Legacy code")
    var nativeWallet: SolanaAccount? {
        state.value.nativeWallet
    }

    @available(*, deprecated, message: "Legacy code")
    func getWallets() -> [SolanaAccount] {
        state.value
    }
}
