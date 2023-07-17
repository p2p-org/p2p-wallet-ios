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

    // MARK: - Service

    let priceService: PriceService

    let errorObservable: ErrorObserver

    public let realtimeService: RealtimeSolanaAccountService?

    // MARK: - Properties

    var subscriptions = [AnyCancellable]()

    // MARK: - Source

    /// The stream of account by rpc call to node.
    let fetchedAccountsByRpc: AsyncValue<[Account]>

    /// Requested token price base on final stream.
    let priceStream: CurrentValueSubject<[SomeToken: TokenPrice?], Never> = .init([:])

    /// The final stream origin base on additional updating through socket.
    let accountsStream: CurrentValueSubject<AsyncValueState<[Account]>, Never> = .init(.init(value: []))

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
        self.priceService = priceService
        self.errorObservable = errorObservable

        // Setup async value
        fetchedAccountsByRpc = SolanaAccountAsyncValue(
            initialItem: [],
            accountStorage: accountStorage,
            solanaAPIClient: solanaAPIClient,
            tokensService: tokensService,
            errorObservable: errorObservable
        )

        // Emit origin stream to final stream
        fetchedAccountsByRpc.statePublisher
            .sink { [weak accountsStream] state in
                accountsStream?.value.status = state.status
                accountsStream?.value.error = state.error
            }
            .store(in: &subscriptions)

        fetchedAccountsByRpc.statePublisher.map(\.value)
            .removeDuplicates()
            .sink { [weak accountsStream] accounts in
                accountsStream?.value.value = accounts
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

        // Subscribe solana realtime service for listening balance changing.
        realtimeService?
            .update
            .sink { [weak self] account in
                self?.onUpdateAccount(account: account)
            }
            .store(in: &subscriptions)

        /// Update price in case there are new accounts or changing in price from price service.
        Publishers.Merge(
            // There is a new changes in accounts.
            accountsStream
                .filter { $0.status == .initializing || $0.status == .ready }
                .map { _ in },
            // There is a change in price service.
            priceService
                .onChangePublisher
        )
        .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.fetchPrice(fiat: fiat)
        }
        .store(in: &subscriptions)

        // Emit data to output
        let accountsAggregator = SolanaAccountsAggregator()
        Publishers
            .CombineLatest(accountsStream, priceStream)
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
        try await fetchedAccountsByRpc.fetch()?.value
    }

    /// Fetch prices for current accounts.
    internal func fetchPrice(fiat: String) {
        Task { [priceService, errorObservable, priceStream] in
            do {
                let prices = try await priceService.getPrices(
                    tokens: state.value.map(\.token),
                    fiat: fiat
                )

                priceStream.send(prices)
            } catch {
                errorObservable.handleError(error)
            }
        }
    }

    /// Update single accounts.
    internal func onUpdateAccount(account: SolanaAccount) {
        var state = accountsStream.value

        let matchIdx = state.value
            .firstIndex { searchedAccount in
                searchedAccount.token.address == account.token.address
            }

        if let matchIdx {
            state.value[matchIdx] = account
        } else {
            state.value.append(account)
        }

        accountsStream.send(state)
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
    @available(*, deprecated, message: "Legacy code")
    var nativeWallet: SolanaAccount? {
        state.value.nativeWallet
    }

    @available(*, deprecated, message: "Legacy code")
    func getWallets() -> [SolanaAccount] {
        state.value
    }
}

internal class SolanaAccountAsyncValue: AsyncValue<[SolanaAccount]> {
    enum Error: Swift.Error {
        case authorityError
    }

    init(
        initialItem: [SolanaAccount],
        accountStorage: SolanaAccountStorage,
        solanaAPIClient: SolanaAPIClient,
        tokensService: SolanaTokensService,
        errorObservable: any ErrorObserver
    ) {
        super.init(initialItem: initialItem) { () async -> ([SolanaAccount]?, Swift.Error?) in
            guard let accountAddress = accountStorage.account?.publicKey.base58EncodedString else {
                return (nil, Error.authorityError)
            }

            var newAccounts: [SolanaAccount] = []

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

                let solanaAccount = SolanaAccount(
                    address: accountAddress,
                    lamports: balance,
                    token: try await tokensService.nativeToken
                )

                newAccounts = [solanaAccount] + resolved
                    .map { accountBalance -> SolanaAccount? in
                        guard let pubkey = accountBalance.pubkey else {
                            return nil
                        }

                        return SolanaAccount(
                            address: pubkey,
                            lamports: accountBalance.lamports ?? 0,
                            token: accountBalance.token
                        )
                    }
                    .compactMap { $0 }

                return (newAccounts, nil)
            } catch {
                errorObservable.handleError(error)
                return (nil, error)
            }
        }
    }
}
