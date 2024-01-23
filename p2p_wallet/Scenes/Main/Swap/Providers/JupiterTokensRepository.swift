import Combine
import Foundation
import Jupiter
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import TokenService

protocol JupiterTokensRepository {
    var status: AnyPublisher<JupiterDataStatus, Never> { get }

    func load() async
}

enum JupiterDataStatus {
    case initial
    case loading
    case ready(jupiterTokens: [SolanaToken])
    case failed
}

final class JupiterTokensRepositoryImpl: JupiterTokensRepository {
    var status: AnyPublisher<JupiterDataStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    // MARK: - Dependencies

    private let jupiterClient: JupiterAPI
    private let localProvider: JupiterTokensProvider
    @Injected private var tokensService: SolanaTokensService

    // MARK: - Private params

    private var statusSubject = CurrentValueSubject<JupiterDataStatus, Never>(.initial)
    private var task: Task<Void, Never>?

    let loadingPeriodInMinutes: Int = 60 * 24 // 1 days

    init(provider: JupiterTokensProvider, jupiterClient: JupiterAPI) {
        localProvider = provider
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
            var jupiterTokens: [SolanaToken]
            
            try Task.checkCancellation()

            // get the date component
            var dayComponent = DateComponents()
            dayComponent.minute = loadingPeriodInMinutes

            // get cachedData if it is not expired
            if let cachedData = localProvider.getCachedData(),
               let dateToExpired = Calendar.current.date(byAdding: dayComponent, to: cachedData.created),
               Date() < dateToExpired
            {
                jupiterTokens = cachedData.tokens
            }

            // retrive to get data
            else {
                // clear expired data
                localProvider.clear()

                // get new data
                jupiterTokens = try await jupiterClient.getTokens()
                

                // save new data
                try localProvider.save(tokens: jupiterTokens)
            }

            // get solana cached token list
            let solanaTokens = try await tokensService.all()

            // map solanaTokens to jupiter token
            jupiterTokens = jupiterTokens.map { jupiterToken in
                if var token = solanaTokens[jupiterToken.mintAddress] {
                    // join tags
                    token.tags = Array(Set(token.tags + jupiterToken.tags))
                    return token
                }
                return jupiterToken
            }

            // return status ready
            try Task.checkCancellation()
            statusSubject.send(.ready(jupiterTokens: jupiterTokens))
        } catch {
            guard !(error is CancellationError) else {
                return
            }
            statusSubject.send(.failed)
        }
    }
}
