import Combine
import NameService
import Resolver
import SolanaSwift

protocol CreateNameService {
    var transactionDetails: AnyPublisher<(isSuccess: Bool, transaction: String), Never> { get }
    func send(transaction: String, name: String, owner: String)
}

final class CreateNameServiceImpl: CreateNameService {
    var transactionDetails: AnyPublisher<(isSuccess: Bool, transaction: String), Never> {
        transactionDetailsSubject.eraseToAnyPublisher()
    }

    @Injected private var solanaAPIClient: SolanaAPIClient
    @Injected private var nameCache: NameServiceCacheType

    private let transactionDetailsSubject = PassthroughSubject<(isSuccess: Bool, transaction: String),
        Never>()

    func send(transaction: String, name: String, owner: String) {
        Task {
            do {
                _ = try await solanaAPIClient.sendTransaction(
                    transaction: transaction,
                    configs: RequestConfiguration(encoding: "base64")!
                )
                nameCache.save(name, for: owner)
                transactionDetailsSubject.send((isSuccess: true, transaction: transaction))
            } catch {
                debugPrint(error)
                transactionDetailsSubject.send((isSuccess: false, transaction: transaction))
            }
        }
    }
}
