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
    var tokens: AnyPublisher<JupiterTokensData, Never> { get }

    func load() async throws
}

final class JupiterTokensRepositoryImpl: JupiterTokensRepository {

    @MainActor var state: AnyPublisher<JupiterTokensState, Never> {
        stateSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    var tokens: AnyPublisher<JupiterTokensData, Never> {
        dataSubject.eraseToAnyPublisher()
    }

    // MARK: - Dependencies
    private let jupiterClient: JupiterAPI
    private let localProvider: JupiterTokensProvider
    @Injected private var walletsRepository: WalletsRepository

    // MARK: - Private params
    @Published private var stateSubject = CurrentValueSubject<JupiterTokensState, Never>(.loading)
    @Published private var dataSubject = CurrentValueSubject<JupiterTokensData, Never>(.init(tokens: [], userWallets: []))

    init(provider: JupiterTokensProvider, jupiterClient: JupiterAPI) {
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
            dataSubject.send(JupiterTokensData(tokens: swapTokens, userWallets: wallets))
            stateSubject.send(.loaded)
        }
        catch {
            stateSubject.send(.error)
        }
    }
}
