import Jupiter
import Combine
import SolanaSwift
import Resolver

public enum SwapWalletsState {
    case initialized
    case loading
    case loaded
    case error
}

struct SwapWalletsData {
    let tokens: [SwapToken]
    let userWallets: [Wallet]
}

protocol SwapWalletsRepository {
    var state: AnyPublisher<SwapWalletsState, Never> { get }
    var tokens: AnyPublisher<SwapWalletsData, Never> { get }

    func load() async throws
}

final class SwapWalletsRepositoryImpl: SwapWalletsRepository {

    @MainActor var state: AnyPublisher<SwapWalletsState, Never> {
        stateSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var tokens: AnyPublisher<SwapWalletsData, Never> {
        dataSubject.eraseToAnyPublisher()
    }

    // MARK: - Dependencies
    private let jupiterClient: JupiterAPI
    private let localProvider: SwapWalletsProvider
    @Injected private var walletsRepository: WalletsRepository

    // MARK: - Private params
    @Published private var stateSubject = CurrentValueSubject<SwapWalletsState, Never>(.loading)
    @Published private var dataSubject = CurrentValueSubject<SwapWalletsData, Never>(.init(tokens: [], userWallets: []))

    init(provider: SwapWalletsProvider, jupiterClient: JupiterAPI) {
        self.localProvider = provider
        self.jupiterClient = jupiterClient
        self.stateSubject.send(.initialized)
    }

    func load() async throws {
        stateSubject.send(.loading)
        do {
            let jupiterTokens: [Jupiter.Token]
            if let cachedData = localProvider.getTokens() {
                jupiterTokens = cachedData
            } else {
                jupiterTokens = try await jupiterClient.getTokens()
                try localProvider.save(tokens: jupiterTokens)
            }

            let wallets = walletsRepository.getWallets()
            let swapTokens = jupiterTokens.map { jupiterToken in
                if let userWallet = wallets.first(where: { $0.mintAddress == jupiterToken.address }) {
                    return SwapToken(jupiterToken: jupiterToken, userWallet: userWallet)
                }
                return SwapToken(jupiterToken: jupiterToken, userWallet: nil)
            }
            dataSubject.send(SwapWalletsData(tokens: swapTokens, userWallets: wallets))
            stateSubject.send(.loaded)
        }
        catch {
            stateSubject.send(.error)
        }
    }
}
