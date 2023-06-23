import Foundation
import KeyAppKitCore
@testable import Onboarding

class MockWalletMetadataProvider: WalletMetadataProvider {
    var value: WalletMetaData?

    var ready: Bool { true }

    func acquireWrite() async {}

    func releaseWrite() async {}

    func load(for _: UserWallet) async throws -> WalletMetaData? {
        value
    }

    func save(for _: UserWallet, metadata: WalletMetaData?) async throws {
        value = metadata
    }
}

class TestableWalletMetadataProvider: WalletMetadataProvider {
    var acquireWriteCount = 0
    var releaseWriteCount = 0
    var loadCallsCount = 0
    var saveCallsCount = 0
    var loadResult: Result<WalletMetaData?, Error>?
    var saveResult: Result<Void, Error>?
    var saveCallMetadata: WalletMetaData?

    var ready: Bool { true }

    func acquireWrite() async {
        acquireWriteCount += 1
    }

    func releaseWrite() async {
        releaseWriteCount += 1
    }

    func load(for _: UserWallet) async throws -> WalletMetaData? {
        loadCallsCount += 1
        if let result = loadResult {
            return try result.get()
        } else {
            throw WalletMetadataServiceImpl.Error.missingLocalMetadata
        }
    }

    func save(for _: UserWallet, metadata: WalletMetaData?) async throws {
        saveCallsCount += 1
        saveCallMetadata = metadata
        if let result = saveResult {
            try result.get()
        } else {
            throw WalletMetadataServiceImpl.Error.missingRemoteMetadata
        }
    }
}
