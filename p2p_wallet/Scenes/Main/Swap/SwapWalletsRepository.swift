import Jupiter
import Combine
import SolanaSwift
import Resolver

public enum SwapWalletsState {
    case loading
    case loaded
    case error
}

struct SwapWalletsData {
    let userTokens: [Wallet]
    let alljupiterTokens: [SolanaSwift.Token]
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
    private let jupiterClient = JupiterRestClientAPI(version: .v4)
    @Injected private var walletsRepository: WalletsRepository

    // MARK: - Private params
    @Published private var stateSubject = CurrentValueSubject<SwapWalletsState, Never>(.loading)
    @Published private var dataSubject = CurrentValueSubject<SwapWalletsData, Never>(.init(userTokens: [], alljupiterTokens: []))

    func load() async throws {
        stateSubject.send(.loading)
        do {
            let tokens = try await jupiterClient.getTokens()

            let wallets = walletsRepository.getWallets()
            let userJupiterTokens = wallets.filter { wallet in
                return tokens.contains(where: { jupiterToken in
                    jupiterToken.address == wallet.mintAddress
                })
            }
            dataSubject.send(SwapWalletsData(userTokens: userJupiterTokens, alljupiterTokens: tokens))
            stateSubject.send(.loaded)
        }
        catch {
            stateSubject.send(.error)
        }

    }
}
