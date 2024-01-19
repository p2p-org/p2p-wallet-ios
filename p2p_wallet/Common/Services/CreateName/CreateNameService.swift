import AnalyticsManager
import Combine
import NameService
import Resolver
import SolanaSwift

protocol CreateNameService {
    var createNameResult: AnyPublisher<Bool, Never> { get }
    func create(username: String, domain: String)
}

final class CreateNameServiceImpl: CreateNameService {
    var createNameResult: AnyPublisher<Bool, Never> {
        createNameResultSubject.eraseToAnyPublisher()
    }

    @Injected private var solanaAPIClient: SolanaAPIClient
    @Injected private var nameCache: NameServiceCacheType
    @Injected private var nameStorage: NameStorageType
    @Injected private var nameService: NameService
    @Injected private var storage: SolanaAccountStorage

    private let createNameResultSubject = PassthroughSubject<Bool, Never>()

    func create(username: String, domain: String) {
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

                let name = "\(username)\(domain)"
                nameStorage.save(name: name)
                nameCache.save(name, for: account.publicKey.base58EncodedString)
                createNameResultSubject.send(true)
            } catch {
                createNameResultSubject.send(false)
                let data = await AlertLoggerDataBuilder.buildLoggerData(error: error)
                DefaultLogManager.shared.log(
                    event: "Name Create iOS Alarm",
                    logLevel: .alert,
                    data: CreateNameAlertLoggerErrorMessage(
                        name: username,
                        error: error.readableDescription,
                        userPubKey: data.userPubkey
                    )
                )

                Resolver.resolve(AnalyticsManager.self).log(title: "Name Create iOS Error", error: error)
            }
        }
    }
}
