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
    let userTokens: [Wallet]
    let jupiterTokens: [Jupiter.Token]
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
    @Published private var dataSubject = CurrentValueSubject<SwapWalletsData, Never>(.init(userTokens: [], jupiterTokens: []))

    init(provider: SwapWalletsProvider, jupiterClient: JupiterAPI) {
        self.localProvider = provider
        self.jupiterClient = jupiterClient
        self.stateSubject.send(.initialized)
    }

    func load() async throws {
        stateSubject.send(.loading)
        do {
            let tokens: [Jupiter.Token]
            if let cachedData = localProvider.getTokens() {
                tokens = cachedData
            } else {
                tokens = try await jupiterClient.getTokens()
                try localProvider.save(tokens: tokens)
            }

            let wallets = walletsRepository.getWallets()
            let userJupiterTokens = wallets.filter { wallet in
                tokens.contains(where: { $0.address == wallet.mintAddress })
            }
            dataSubject.send(SwapWalletsData(userTokens: userJupiterTokens, jupiterTokens: tokens))
            stateSubject.send(.loaded)
        }
        catch {
            stateSubject.send(.error)
        }
    }
}
