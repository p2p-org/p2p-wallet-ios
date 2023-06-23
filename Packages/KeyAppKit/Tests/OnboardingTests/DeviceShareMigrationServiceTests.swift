import XCTest

import Combine
import KeyAppKitCore
@testable import Onboarding

class DeviceShareMigrationServiceTests: XCTestCase {
    func testIsMigrationAvailable_Web3UserWithoutDeviceShare_ReturnsTrue() {
        // Prepare the test data
        let isWeb3User: Bool? = true
        let hasDeviceShare = false

        // Invoke the static method
        let result = DeviceShareMigrationService.isMigrationAvailable(
            isWeb3User: isWeb3User,
            hasDeviceShare: hasDeviceShare
        )

        // Perform assertions
        XCTAssertTrue(result) // Migration should be available
    }

    func testIsMigrationAvailable_Web3UserWithDeviceShare_ReturnsFalse() {
        // Prepare the test data
        let isWeb3User: Bool? = true
        let hasDeviceShare = true

        // Invoke the static method
        let result = DeviceShareMigrationService.isMigrationAvailable(
            isWeb3User: isWeb3User,
            hasDeviceShare: hasDeviceShare
        )

        // Perform assertions
        XCTAssertFalse(result) // Migration should not be available
    }

    func testIsMigrationAvailable_NonWeb3User_ReturnsFalse() {
        // Prepare the test data
        let isWeb3User: Bool? = false
        let hasDeviceShare = false

        // Invoke the static method
        let result = DeviceShareMigrationService.isMigrationAvailable(
            isWeb3User: isWeb3User,
            hasDeviceShare: hasDeviceShare
        )

        // Perform assertions
        XCTAssertFalse(result) // Migration should not be available
    }

    func testIsMigrationAvailable_NonWeb3UserWithDeviceShare_ReturnsFalse() {
        // Prepare the test data
        let isWeb3User: Bool? = false
        let hasDeviceShare = true

        // Invoke the static method
        let result = DeviceShareMigrationService.isMigrationAvailable(
            isWeb3User: isWeb3User,
            hasDeviceShare: hasDeviceShare
        )

        // Perform assertions
        XCTAssertFalse(result) // Migration should not be available
    }

    func testIsMigrationAvailable_NilWeb3User_ReturnsFalse() {
        // Prepare the test data
        let isWeb3User: Bool? = nil
        let hasDeviceShare = false

        // Invoke the static method
        let result = DeviceShareMigrationService.isMigrationAvailable(
            isWeb3User: isWeb3User,
            hasDeviceShare: hasDeviceShare
        )

        // Perform assertions
        XCTAssertFalse(result) // Migration should not be available
    }

    func testMigrate_WhenMigrationAvailableAndValidEthAddress_MigratesDeviceShare() async throws {
        // Prepare the test data
        let isWeb3User: Bool? = true
        let hasDeviceShare = false

        let currentWallet = MockCurrentUserWallet.random(web3AuthUser: true)
        let errorObserver = TestableErrorObserver()
        let facade = TKeyMockupFacade(ethAddress: currentWallet.value?.ethAddress)
        let deviceShareStorage = TestableDeviceShareStorage()

        var localMetadataProvider = MockWalletMetadataProvider()
        var remoteMetadataProvider = MockWalletMetadataProvider()

        let metadataService = WalletMetadataServiceImpl(
            currentUserWallet: MockCurrentUserWallet.random(web3AuthUser: true),
            errorObserver: errorObserver,
            localMetadataProvider: localMetadataProvider,
            remoteMetadataProvider: [remoteMetadataProvider]
        )

        // Create an instance of DeviceShareMigrationService
        let service = DeviceShareMigrationService(
            isWeb3AuthUser: Just(isWeb3User).eraseToAnyPublisher(),
            hasDeviceShare: Just(hasDeviceShare).eraseToAnyPublisher(),
            errorObserver: errorObserver
        )

        // Stub the required dependencies
        let initialMetadata = WalletMetaData(
            ethPublic: currentWallet.value!.ethAddress!,
            deviceName: "D1",
            email: "E1",
            authProvider: "A1",
            phoneNumber: "P1"
        )

        await metadataService.update(initialMetadata)

        try await Task.sleep(nanoseconds: 1000)

        // Perform the migration
        do {
            try await service.migrate(
                on: facade,
                for: currentWallet.value!.ethAddress!,
                deviceShareStorage: deviceShareStorage,
                metadataService: metadataService
            )

            // Check if the migration was successful by asserting that a new device share was saved
            XCTAssertEqual(deviceShareStorage.deviceShare, "newDeviceShare")
            XCTAssertEqual(metadataService.metadata.value?.deviceName, Device.currentDevice())
            XCTAssertNil(metadataService.metadata.error)
        } catch {
            XCTFail("Migration should not throw an error")
        }
    }

    class TestableDeviceShareStorage: DeviceShareManager {
        var savedDeviceShare: String?

        func save(deviceShare: String) {
            savedDeviceShare = deviceShare
        }

        var deviceShare: String? { savedDeviceShare }

        var deviceSharePublisher: AnyPublisher<String?, Never> { fatalError() }
    }
}
