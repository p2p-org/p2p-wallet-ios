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
    // MARK: - Dependencies
    private let jupiterClient: JupiterAPI
    private let localProvider: JupiterTokensProvider
    @Injected private var walletsRepository: WalletsRepository
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Private params
    private var statusSubject = CurrentValueSubject<JupiterDataStatus, Never>(.initial)

    init(provider: JupiterTokensProvider, jupiterClient: JupiterAPI) {
        self.localProvider = provider
        self.jupiterClient = jupiterClient
        
        bind()
    }

    func load() async {
        statusSubject.send(.loading)
        do {
            let jupiterTokens: [Token]
            let routeMap: RouteMap
            if let cachedData = localProvider.getCachedData() {
                jupiterTokens = cachedData.tokens
                routeMap = cachedData.routeMap
            } else {
                jupiterTokens = try await jupiterClient.getTokens()
                routeMap = try await jupiterClient.routeMap()
                try localProvider.save(tokens: jupiterTokens, routeMap: routeMap)
            }
            
            mapTokens()
        } catch {
            statusSubject.send(.failed)
        }
    }
    
    // MARK: - Helpers

    private func bind() {
        walletsRepository.dataPublisher
            .sink { [weak self] _ in
                self?.mapTokens()
            }
            .store(in: &subscriptions)
    }
    
    private func mapTokens() {
        // get catchedData
        guard let cachedData = localProvider.getCachedData()
        else {
            return
        }
        
        let jupiterTokens = cachedData.tokens
        let routeMap = cachedData.routeMap
        
        // get user wallets
        let wallets = walletsRepository.getWallets()
        let swapTokens = jupiterTokens.map { jupiterToken in
            if let userWallet = wallets.first(where: { $0.mintAddress == jupiterToken.address }) {
                return SwapToken(token: jupiterToken, userWallet: userWallet)
            }
            return SwapToken(token: jupiterToken, userWallet: nil)
        }
        statusSubject.send(.ready(swapTokens: swapTokens, routeMap: routeMap))
    }
}
