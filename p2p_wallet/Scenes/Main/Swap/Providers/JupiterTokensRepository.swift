import Jupiter
import Combine
import SolanaSwift
import Resolver

struct JupiterTokensData {
    let tokens: [SwapToken]
    let userWallets: [Wallet]
}

protocol JupiterTokensRepository {
    var status: AnyPublisher<JupiterDataStatus, Never> { get }

    func load() async
}

enum JupiterDataStatus {
    case initial
    case loading
    case ready(swapTokens: [SwapToken], routeMap: RouteMap)
    case failed
}

final class JupiterTokensRepositoryImpl: JupiterTokensRepository {

    var status: AnyPublisher<JupiterDataStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }
    var routeMap = [String: [String]]()

    // MARK: - Dependencies
    private let jupiterClient: JupiterAPI
    private let localProvider: JupiterTokensProvider
    @Injected private var walletsRepository: WalletsRepository

    // MARK: - Private params
    private var statusSubject = CurrentValueSubject<JupiterDataStatus, Never>(.initial)

    init(provider: JupiterTokensProvider, jupiterClient: JupiterAPI) {
        self.localProvider = provider
        self.jupiterClient = jupiterClient
    }

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
