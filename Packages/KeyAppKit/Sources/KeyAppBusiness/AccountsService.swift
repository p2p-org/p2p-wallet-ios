import Foundation
import SolanaSwift
import KeyAppKitCore
import Web3
import Combine

public protocol AccountsService {
    /// Update accounts state
    func fetch() async throws
    
    // MARK: - Solana

    /// Solana accounts state publisher
    var solanaAccountsStatePublisher: AnyPublisher<AsyncValueState<[SolanaAccount]>, Never> { get }
    
    /// Solana accounts state
    var solanaAccountsState: AsyncValueState<[SolanaAccount]> { get }
    
    /// Reload solana accounts
    @available(*, deprecated, message: "use fetch to reload all accounts instead")
    func reloadSolanaAccounts() async throws
    
    // MARK: - Ethereum

    /// Ethereum accounts state publisher
    var ethereumAccountsStatePublisher: AnyPublisher<AsyncValueState<[EthereumAccount]>, Never> { get }
    
    /// Ethereum accounts state
    var ethereumAccountsState: AsyncValueState<[EthereumAccount]> { get }
}

public class AccountsServiceImpl: AccountsService {
    
    // MARK: - Nested types
    
    /// Arguments to construct `SolanaAccountsProvider`
    public struct SolanaChainArgs {
        public let fiat: String
        public let accountStorage: SolanaAccountStorage
        public let apiClient: SolanaAPIClient
        public let tokensService: SolanaTokensRepository
        public let priceService: SolanaPriceService
        public let accountObservableService: SolanaAccountsObservableService
        public let errorObservable: any ErrorObserver
        
        public init(
            fiat: String,
            accountStorage: SolanaAccountStorage,
            apiClient: SolanaAPIClient,
            tokensService: SolanaTokensRepository,
            priceService: SolanaPriceService,
            accountObservableService: SolanaAccountsObservableService,
            errorObservable: ErrorObserver
        ) {
            self.fiat = fiat
            self.accountStorage = accountStorage
            self.apiClient = apiClient
            self.tokensService = tokensService
            self.priceService = priceService
            self.accountObservableService = accountObservableService
            self.errorObservable = errorObservable
        }
    }
    
    /// Arguments to construct `EthereumAccountsProvider`
    public struct EthereumChainArgs {
        public let address: String
        public let web3: Web3
        public let ethereumTokenRepository: EthereumTokensRepository
        public let priceService: EthereumPriceService
        public let fiat: String
        public let errorObservable: any ErrorObserver
        
        public init(
            address: String,
            web3: Web3,
            ethereumTokenRepository: EthereumTokensRepository,
            priceService: EthereumPriceService,
            fiat: String,
            errorObservable: ErrorObserver
        ) {
            self.address = address
            self.web3 = web3
            self.ethereumTokenRepository = ethereumTokenRepository
            self.priceService = priceService
            self.fiat = fiat
            self.errorObservable = errorObservable
        }
    }
    
    // MARK: - Properties

    private let isEthAddressAvailable: Bool
    private let solanaAccountsProvider: SolanaAccountsProvider
    private let ethereumAccountsProvider: EthereumAccountsProvider?
    
    public var solanaAccountsStatePublisher: AnyPublisher<AsyncValueState<[SolanaAccount]>, Never> {
        solanaAccountsProvider.$state.eraseToAnyPublisher()
    }
    
    public var solanaAccountsState: AsyncValueState<[SolanaAccount]> {
        solanaAccountsProvider.state
    }
    
    public var ethereumAccountsStatePublisher: AnyPublisher<AsyncValueState<[EthereumAccount]>, Never> {
        ethereumAccountsProvider?.$state.eraseToAnyPublisher() ??
        Empty(completeImmediately: true).eraseToAnyPublisher()
    }
    
    public var ethereumAccountsState: AsyncValueState<[EthereumAccount]> {
        ethereumAccountsProvider?.state ?? .init(status: .initializing, value: [])
    }
    
    // MARK: - Initializer

    public init(
        solana: SolanaChainArgs,
        ethereum: EthereumChainArgs?,
        isEthAddressAvailable: Bool
    ) {
        self.isEthAddressAvailable = isEthAddressAvailable
        self.solanaAccountsProvider = .init(
            accountStorage: solana.accountStorage,
            solanaAPIClient: solana.apiClient,
            tokensService: solana.tokensService,
            priceService: solana.priceService,
            accountObservableService: solana.accountObservableService,
            fiat: solana.fiat,
            errorObservable: solana.errorObservable
        )
        
        if isEthAddressAvailable, let ethereum {
            self.ethereumAccountsProvider = .init(
                address: ethereum.address,
                web3: ethereum.web3,
                ethereumTokenRepository: ethereum.ethereumTokenRepository,
                priceService: ethereum.priceService,
                fiat: ethereum.fiat,
                errorObservable: ethereum.errorObservable
            )
        } else {
            self.ethereumAccountsProvider = nil
        }
    }
    
    /// Update accounts state
    public func fetch() async throws {
        // use throwing task group to make solanaAccountService.fetch() and ethereumAccountService.fetch() run parallelly
        // and support another chains later
        try await withThrowingTaskGroup(of: Void.self) { group in
            // solana
            group.addTask { [weak self] in
                guard let self else { return }
                try await self.solanaAccountsProvider.fetch()
            }
            
            // ethereum
            if isEthAddressAvailable {
                group.addTask { [weak self] in
                    guard let self,
                          let ethereumAccountsProvider = self.ethereumAccountsProvider
                    else { return }
                    try await ethereumAccountsProvider.fetch()
                }
            }
            
            // another chains goes here
            
            // await values
            for try await _ in group {}
        }
    }
    
    /// Reload solana accounts
    @available(*, deprecated, message: "use fetch to reload all accounts instead")
    public func reloadSolanaAccounts() async throws {
        try await solanaAccountsProvider.fetch()
    }
}
