import Combine
import Foundation
import KeyAppKitCore
import Web3

public final class EthereumAccountsService: NSObject, AccountsService {
    public typealias Account = EthereumAccount

    // MARK: - Service

    let priceService: PriceService

    let errorObservable: ErrorObserver

    // MARK: - Properties

    var subscriptions = [AnyCancellable]()

    // MARK: - Source

    let accounts: AsyncValue<[Account]>

    let accountsStream: CurrentValueSubject<AsyncValueState<[Account]>, Never> = .init(.init(value: []))

    let stateSubject: CurrentValueSubject<AsyncValueState<[Account]>, Never> = .init(.init(value: []))

    // MARK: - Output

    public var statePublisher: AnyPublisher<AsyncValueState<[Account]>, Never> { stateSubject.eraseToAnyPublisher() }

    public var state: AsyncValueState<[Account]> { stateSubject.value }

    /// Requested token price base on final stream.
    let priceStream: CurrentValueSubject<[SomeToken: TokenPrice], Never> = .init([:])

    public init(
        address: String,
        web3: Web3,
        ethereumTokenRepository: EthereumTokensRepository,
        priceService: PriceService,
        fiat: String,
        errorObservable: any ErrorObserver,
        enable: Bool
    ) {
        self.priceService = priceService
        self.errorObservable = errorObservable

        accounts = EthereumAccountAsyncValue(
            address: address,
            web3: web3,
            ethereumTokenRepository: ethereumTokenRepository,
            errorObservable: errorObservable,
            enable: enable
        )

        super.init()

        accounts
            .statePublisher
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .map { [weak self] state in
                self?.fetchPrice(state: state, fiat: fiat)
            }
            .compactMap { $0 }
            .switchToLatest()
            .sink { [weak stateSubject] state in
                stateSubject?.send(state)
            }
            .store(in: &subscriptions)

        priceService
            .onChangePublisher
            .sink { [weak accounts] in
                accounts?.state.status = .ready
            }
            .store(in: &subscriptions)

        // Update every 30 seconds accounts
        Timer
            .publish(every: 30, on: .main, in: .default)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in self?.accounts.fetch() })
            .store(in: &subscriptions)

        errorObservable
            .handleAsyncValue(accounts)
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

    internal func fetchPrice(
        state: AsyncValueState<[EthereumAccount]>,
        fiat: String
    ) -> Future<AsyncValueState<[Account]>, Never> {
        Future { [priceService, errorObservable] promise in
            Task { [weak priceService, errorObservable] in
                // Price service is unavailable
                guard let priceService else {
                    promise(.success(state))
                    return
                }

                var prices: [SomeToken: TokenPrice] = [:]
                var caughtError: Error?

                // Fetch price
                do {
                    prices = try await priceService.getPrices(
                        tokens: state.value.map(\.token),
                        fiat: fiat
                    )
                } catch {
                    errorObservable.handleError(error)
                    caughtError = error
                }

                // Aggregate
                var aggregatedState = state.apply { accounts in
                    var newAccounts = accounts

                    for index in newAccounts.indices {
                        let token = newAccounts[index].token.asSomeToken
                        if let price = prices[token] {
                            newAccounts[index].price = .init(
                                currencyCode: fiat.uppercased(),
                                value: price.value,
                                token: token
                            )
                        }
                    }

                    return newAccounts
                }

                // Assign error in case there is no previously error
                if aggregatedState.error == nil {
                    aggregatedState.error = caughtError
                }

                promise(.success(aggregatedState))
            }
        }
    }
}

internal class EthereumAccountAsyncValue: AsyncValue<[EthereumAccount]> {
    enum Error: Swift.Error {
        case invalidEthereumAddress
    }

    init(address: String,
         web3: Web3,
         ethereumTokenRepository: EthereumTokensRepository,
         errorObservable: any ErrorObserver,
         enable: Bool)
    {
        super.init(initialItem: []) { () async -> ([EthereumAccount]?, Swift.Error?) in
            let address = try? EthereumAddress(hex: address, eip55: false)
            guard let address else {
                return (nil, Error.invalidEthereumAddress)
            }

            // Service is disabled
            if !enable {
                return ([], nil)
            }

            do {
                // Fetch balance and token balances
                let (balance, wallet) = try await(
                    web3.eth.getBalance(address: address, block: .latest),
                    web3.eth.getTokenBalances(address: address)
                )

                let nativeAccount = try EthereumAccount(
                    address: address.hex(eip55: false),
                    token: await ethereumTokenRepository.nativeToken,
                    balance: balance.quantity,
                    price: nil
                )

                // Build token accounts
                let tokenBalances = wallet.tokenBalances

                // Build token accounts
                let resolvedTokenAccounts: [EthereumAccount] = try await Self.resolveTokenAccounts(
                    address: address.hex(eip55: false),
                    balances: tokenBalances,
                    repository: ethereumTokenRepository
                )

                return ([nativeAccount] + resolvedTokenAccounts, nil)
            } catch {
                errorObservable.handleError(error)
                return (nil, error)
            }
        }
    }

    /// Method resolve ethereum erc-20 token accounts.
    internal static func resolveTokenAccounts(
        address: String,
        balances: [EthereumTokenBalances.Balance],
        repository: EthereumTokensRepository
    ) async throws -> [EthereumAccount] {
        if balances.isEmpty {
            return []
        }

        var result: [EthereumAccount] = []
        let tokens = try await repository.resolve(addresses: balances.map(\.contractAddress))

        for balance in balances {
            guard let token = tokens[balance.contractAddress] else {
                continue
            }

            result.append(EthereumAccount(address: address, token: token, balance: balance.tokenBalance ?? 0))
        }

        return result
    }
}
