import Combine
import NameService
import Resolver
import SolanaSwift

protocol CreateNameService {
    var transactionDetails: AnyPublisher<Bool, Never> { get }
    func create(username: String)
}

final class CreateNameServiceImpl: CreateNameService {
    var transactionDetails: AnyPublisher<Bool, Never> {
        transactionDetailsSubject.eraseToAnyPublisher()
    }

    @Injected private var solanaAPIClient: SolanaAPIClient
    @Injected private var nameCache: NameServiceCacheType
    @Injected private var nameService: NameService
    @Injected private var storage: AccountStorageType

    private let transactionDetailsSubject = PassthroughSubject<Bool, Never>()

    func create(username: String) {
        Task {
            do {
                guard let account = storage.account else {
                    transactionDetailsSubject.send(false)
                    return
                }

                let createResult = try await self.nameService.create(
                    name: username,
                    publicKey: account.publicKey.base58EncodedString,
                    privateKey: account.secretKey
                )

                _ = try await solanaAPIClient.sendTransaction(
                    transaction: createResult.transaction,
                    configs: RequestConfiguration(encoding: "base64")!
                )

                nameCache.save(username, for: account.publicKey.base58EncodedString)
                transactionDetailsSubject.send(true)
            } catch {
                transactionDetailsSubject.send(false)
            }
        }
    }
}
