import Jupiter
import Combine
import SolanaSwift
import Resolver

/// Tokens data returned by Jupiter
struct JupiterTokensData {
    /// List of Jupiter's supported tokens
    let tokens: [SwapToken]
    /// Wallets owned by user
    let userWallets: [Wallet]
}

/// Repository that handle JupiterTokens
protocol JupiterTokensRepository {
    /// Current status of repository
    var statusPublisher: AnyPublisher<JupiterDataStatus, Never> { get }
    
    /// Load repository
    func load() async
}

/// Status of current JupiterData
enum JupiterDataStatus {
    case initial
    case loading
    case ready(swapTokens: [SwapToken], routeMap: RouteMap)
    case failed
}

/// Default implementaion of JupiterTokensRepository
final class JupiterTokensRepositoryImpl: JupiterTokensRepository {
    // MARK: - Dependencies

    private let jupiterClient: JupiterAPI
    private let localProvider: JupiterTokensProvider
    @Injected private var walletsRepository: WalletsRepository

    // MARK: - Subjects

    private var statusSubject = CurrentValueSubject<JupiterDataStatus, Never>(.initial)
    
    // MARK: - Properties

    var statusPublisher: AnyPublisher<JupiterDataStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    // MARK: - Initializer

    init(provider: JupiterTokensProvider, jupiterClient: JupiterAPI) {
        self.localProvider = provider
        self.jupiterClient = jupiterClient
    }

    // MARK: - Methods

    func load() async {
        statusSubject.send(.loading)
        do {
            let jupiterTokens: [Jupiter.Token]
            let routeMap: RouteMap
            if let cachedData = localProvider.getCachedData() {
                jupiterTokens = cachedData.tokens
                routeMap = cachedData.routeMap
            } else {
                jupiterTokens = try await jupiterClient.getTokens()
                routeMap = try await jupiterClient.routeMap()
                try localProvider.save(tokens: jupiterTokens, routeMap: routeMap)
            }
            
            let wallets = walletsRepository.getWallets()
            let swapTokens = jupiterTokens.map { jupiterToken in
                if let userWallet = wallets.first(where: { $0.mintAddress == jupiterToken.address }) {
                    return SwapToken(jupiterToken: jupiterToken, userWallet: userWallet)
                }
                return SwapToken(jupiterToken: jupiterToken, userWallet: nil)
            }
            statusSubject.send(.ready(swapTokens: swapTokens, routeMap: routeMap))
        } catch {
            statusSubject.send(.failed)
        }
    }
}
