import Jupiter
import Combine
import SolanaSwift
import Resolver

public enum JupiterTokensState {
    case initialized
    case loading
    case loaded
    case error
}

struct JupiterTokensData {
    let tokens: [SwapToken]
    let userWallets: [Wallet]
}

protocol JupiterTokensRepository {
    var state: AnyPublisher<JupiterTokensState, Never> { get }
    var data: AnyPublisher<JupiterData, Never> { get }
    var routeMap: [String: [String]] { get }

    func load() async throws
}

struct JupiterData {
    let swapTokens: [SwapToken]
    let routeMap: RouteMap
}

final class JupiterTokensRepositoryImpl: JupiterTokensRepository {
@MainActor var state: AnyPublisher<JupiterTokensState, Never> {
        $stateSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    var data: AnyPublisher<JupiterData, Never> {
        $dataSubject.eraseToAnyPublisher()
    }
    var routeMap = [String: [String]]()

    // MARK: - Dependencies
    private let jupiterClient: JupiterAPI
    private let localProvider: JupiterTokensProvider
    @Injected private var walletsRepository: WalletsRepository

    // MARK: - Private params
    @Published private var dataSubject: JupiterData

    init(provider: JupiterTokensProvider, jupiterClient: JupiterAPI) {
        self.localProvider = provider
        self.jupiterClient = jupiterClient
        self.dataSubject = JupiterData(swapTokens: [], routeMap: .init(mintKeys: [], indexesRouteMap: [:]))
    }

    func load() async throws {
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
        dataSubject = JupiterData(swapTokens: swapTokens, routeMap: routeMap)
    }
}
