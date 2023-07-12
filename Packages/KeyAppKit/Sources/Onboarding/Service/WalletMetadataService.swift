import Combine
import Foundation
import KeyAppKitCore

public protocol WalletMetadataService {
    func synchronize() async

    func update(_ newMetadata: WalletMetaData) async

    var metadata: AsyncValueState<WalletMetaData?> { get }

    var metadataPublisher: AnyPublisher<AsyncValueState<WalletMetaData?>, Never> { get }
}

public enum WalletMetadataProviderError: Error {
    case invalidAction
    case unauthorised
    case deleteIsNotAllowed
}

public protocol WalletMetadataProvider {
    /// The flag indicated ready for usage the provider
    var ready: Bool { get async }

    func acquireWrite() async
    func releaseWrite() async

    func save(for wallet: UserWallet, metadata: WalletMetaData?) async throws
    func load(for wallet: UserWallet) async throws -> WalletMetaData?
}
