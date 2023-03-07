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

    // MARK: - Private params

    private var statusSubject = CurrentValueSubject<JupiterDataStatus, Never>(.initial)
    private var task: Task<Void, Never>?

    init(provider: JupiterTokensProvider, jupiterClient: JupiterAPI) {
        self.localProvider = provider
        self.jupiterClient = jupiterClient
    }

    func load() async {
        // cancel previous task
        task?.cancel()
        task = nil
        
        // assign task
        task = Task { [weak self] in
            await self?.fetch()
        }
        
        await task?.value
    }
    
    private func fetch() async {
        statusSubject.send(.loading)
        do {
            let jupiterTokens: [Token]
            let routeMap: RouteMap
            
            try Task.checkCancellation()
            
            // get data from memory first
            if let cachedData = localProvider.getCachedData() {
                jupiterTokens = cachedData.tokens
                routeMap = cachedData.routeMap
            }
            
            // retrive to get data
            else {
                (jupiterTokens, routeMap) = try await(
                    jupiterClient.getTokens(),
                    jupiterClient.routeMap()
                )
                try localProvider.save(tokens: jupiterTokens, routeMap: routeMap)
            }
            
            // map userWallets with jupiter tokens
            let wallets = walletsRepository.getWallets()
            let swapTokens = jupiterTokens.map { jupiterToken in
                if let userWallet = wallets.first(where: { $0.mintAddress == jupiterToken.address }) {
                    return SwapToken(token: jupiterToken, userWallet: userWallet)
                }
                return SwapToken(token: jupiterToken, userWallet: nil)
            }
            try Task.checkCancellation()
            statusSubject.send(.ready(swapTokens: swapTokens, routeMap: routeMap))
        } catch {
            guard !(error is CancellationError) else {
                return
            }
            statusSubject.send(.failed)
        }
    }
}
