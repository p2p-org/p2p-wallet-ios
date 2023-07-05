import Combine
import XCTest

import KeyAppKitCore
@testable import Onboarding

class WalletMetadataServiceTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []

    func testSynchronize_WhenCurrentUserWalletNil_ShouldHandleUnauthorizedError() async throws {
        // Give
        let currentUserWallet = MockCurrentUserWallet(nil)
        let errorObserver = TestableErrorObserver()

        let localMetadataProvider = TestableWalletMetadataProvider()
        let remoteMetadataProvider = [TestableWalletMetadataProvider()]

        let walletMetadataService = WalletMetadataServiceImpl(
            currentUserWallet: currentUserWallet,
            errorObserver: errorObserver,
            localMetadataProvider: localMetadataProvider,
            remoteMetadataProvider: remoteMetadataProvider
        )

        // Test
        await walletMetadataService.synchronize()

        // Validate
        XCTAssertEqual(errorObserver.errors.count, 1)
        XCTAssertTrue(errorObserver.serviceError.contains(.unauthorized))
    }

    func testSynchronize_WhenUserWalletEthAddressNil_ShouldHandleNotWeb3AuthUserError() async throws {
        // Give
        let currentUserWallet = MockCurrentUserWallet.random(web3AuthUser: false)
        let errorObserver = TestableErrorObserver()
        let localMetadataProvider = TestableWalletMetadataProvider()
        let remoteMetadataProvider = [TestableWalletMetadataProvider()]
        let walletMetadataService = WalletMetadataServiceImpl(
            currentUserWallet: currentUserWallet,
            errorObserver: errorObserver,
            localMetadataProvider: localMetadataProvider,
            remoteMetadataProvider: remoteMetadataProvider
        )

        // Test
        await walletMetadataService.synchronize()

        // Validate
        XCTAssertEqual(errorObserver.errors.count, 1)
        XCTAssertTrue(errorObserver.serviceError.contains(.notWeb3AuthUser))
    }

    func testSynchronize_WhenLocalAndRemoteMetadataDifferent_ShouldMergeAndSaveMetadata() async throws {
        // Give
        let currentUserWallet = MockCurrentUserWallet.random(web3AuthUser: true)
        let errorObserver = TestableErrorObserver()
        let localMetadataProvider = TestableWalletMetadataProvider()
        let remoteMetadataProvider = [TestableWalletMetadataProvider(), TestableWalletMetadataProvider()]
        let walletMetadataService = WalletMetadataServiceImpl(
            currentUserWallet: currentUserWallet,
            errorObserver: errorObserver,
            localMetadataProvider: localMetadataProvider,
            remoteMetadataProvider: remoteMetadataProvider
        )
        
        var localMetadata = WalletMetaData(
            ethPublic: currentUserWallet.value!.ethAddress!,
            deviceName: "D1",
            email: "E1",
            authProvider: "A1",
            phoneNumber: "P1"
        )
        
        try await Task.sleep(nanoseconds: 1000)
        
        let remoteMetadata1 = WalletMetaData(
            ethPublic: currentUserWallet.value!.ethAddress!,
            deviceName: "D2",
            email: "E1",
            authProvider: "A1",
            phoneNumber: "P1"
        )
        
        try await Task.sleep(nanoseconds: 1000)
        let remoteMetadata2 = WalletMetaData(
            ethPublic: currentUserWallet.value!.ethAddress!,
            deviceName: "D2",
            email: "E1",
            authProvider: "A2",
            phoneNumber: "P1"
        )
        
        localMetadata.phoneNumber = "P3"
        
        localMetadataProvider.loadResult = .success(localMetadata)
        localMetadataProvider.saveResult = .success(())
        
        remoteMetadataProvider[0].loadResult = .success(remoteMetadata1)
        remoteMetadataProvider[0].saveResult = .success(())
        
        remoteMetadataProvider[1].loadResult = .success(remoteMetadata2)
        remoteMetadataProvider[1].saveResult = .success(())
        
        // Test
        await walletMetadataService.synchronize()
        
        // Validate
        XCTAssertEqual(localMetadataProvider.loadCallsCount, 1)
        XCTAssertEqual(localMetadataProvider.saveCallsCount, 1)
        XCTAssertEqual(localMetadataProvider.acquireWriteCount, 0)
        XCTAssertEqual(localMetadataProvider.releaseWriteCount, 0)
        XCTAssertEqual(localMetadataProvider.saveCallMetadata?.deviceName, "D2")
        XCTAssertEqual(localMetadataProvider.saveCallMetadata?.email, "E1")
        XCTAssertEqual(localMetadataProvider.saveCallMetadata?.authProvider, "A2")
        XCTAssertEqual(localMetadataProvider.saveCallMetadata?.phoneNumber, "P3")
        
        XCTAssertEqual(remoteMetadataProvider[0].loadCallsCount, 1)
        XCTAssertEqual(remoteMetadataProvider[0].saveCallsCount, 1)
        XCTAssertEqual(remoteMetadataProvider[0].acquireWriteCount, 1)
        XCTAssertEqual(remoteMetadataProvider[0].releaseWriteCount, 1)
        XCTAssertEqual(remoteMetadataProvider[0].saveCallMetadata?.deviceName, "D2")
        XCTAssertEqual(remoteMetadataProvider[0].saveCallMetadata?.email, "E1")
        XCTAssertEqual(remoteMetadataProvider[0].saveCallMetadata?.authProvider, "A2")
        XCTAssertEqual(remoteMetadataProvider[0].saveCallMetadata?.phoneNumber, "P3")
        
        XCTAssertEqual(remoteMetadataProvider[1].loadCallsCount, 1)
        XCTAssertEqual(remoteMetadataProvider[1].saveCallsCount, 1)
        XCTAssertEqual(remoteMetadataProvider[1].acquireWriteCount, 1)
        XCTAssertEqual(remoteMetadataProvider[1].releaseWriteCount, 1)
        XCTAssertEqual(remoteMetadataProvider[1].saveCallMetadata?.deviceName, "D2")
        XCTAssertEqual(remoteMetadataProvider[1].saveCallMetadata?.email, "E1")
        XCTAssertEqual(remoteMetadataProvider[1].saveCallMetadata?.authProvider, "A2")
        XCTAssertEqual(remoteMetadataProvider[1].saveCallMetadata?.phoneNumber, "P3")
        
        XCTAssertNil(walletMetadataService.metadata.error)
    }
}
