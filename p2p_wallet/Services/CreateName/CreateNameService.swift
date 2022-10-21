import Combine
import NameService
import Resolver
import SolanaSwift

protocol CreateNameService {
    var createNameResult: AnyPublisher<Bool, Never> { get }
    func create(username: String)
}

final class CreateNameServiceImpl: CreateNameService {
    var createNameResult: AnyPublisher<Bool, Never> {
        createNameResultSubject.eraseToAnyPublisher()
    }

    @Injected private var solanaAPIClient: SolanaAPIClient
    @Injected private var nameCache: NameServiceCacheType
    @Injected private var nameStorage: NameStorageType
    @Injected private var nameService: NameService
    @Injected private var storage: AccountStorageType

    private let createNameResultSubject = PassthroughSubject<Bool, Never>()

    func create(username: String) {
        Task {
            do {
                guard let account = storage.account else {
                    createNameResultSubject.send(false)
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

                nameStorage.save(name: username)
                nameCache.save(username, for: account.publicKey.base58EncodedString)
                createNameResultSubject.send(true)
            } catch {
                createNameResultSubject.send(false)
            }
        }
    }
}
