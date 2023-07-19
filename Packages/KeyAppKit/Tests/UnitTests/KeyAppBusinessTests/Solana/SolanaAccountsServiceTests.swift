import XCTest
@testable import KeyAppBusiness

import Combine
import KeyAppKitCore
import SolanaSwift

final class SolanaAccountsServiceTests: XCTestCase {
    // Ensure 10 seconds updating
    func testMonitoringByTimer() async throws {
        let errorObserver = MockErroObserver()
        let solanaAPIClient = MockSolanaAPIClient()
        let keyAppTokenProvider = MockKeyAppTokenProvider()

        let tokenService = MockTokensRepository()
        let priceService = PriceServiceImpl(api: keyAppTokenProvider, errorObserver: errorObserver, lifetime: 60)

        let service = SolanaAccountsService(
            accountStorage: MockAccountStorage(),
            solanaAPIClient: solanaAPIClient,
            tokensService: tokenService,
            priceService: priceService,
            fiat: "usd",
            proxyConfiguration: .init(address: "", port: 1),
            errorObservable: MockErrorObservable()
        )

        // After 1 second
        try await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertEqual(service.state.value.nativeWallet?.lamports, 0)

        solanaAPIClient.balance = 1000

        XCTAssertEqual(service.state.value.nativeWallet?.lamports, 0)

        // After 11 second
        try await Task.sleep(nanoseconds: 14_000_000_000)
        XCTAssertEqual(service.state.value.nativeWallet?.lamports, 1000)
    }

    // Ensure updating by observableService
    func testMonitoringByObservableService() async throws {
        let errorObserver = MockErroObserver()
        let accountStorage = MockAccountStorage()
        let solanaAPIClient = MockSolanaAPIClient()
        let keyAppTokenProvider = MockKeyAppTokenProvider()
        let realtimeSolanaAccountService = MockRealtimeSolanaAccountService()

        let tokenService = MockTokensRepository()
        let priceService = PriceServiceImpl(api: keyAppTokenProvider, errorObserver: errorObserver, lifetime: 60)

        let service = SolanaAccountsService(
            accountStorage: accountStorage,
            solanaAPIClient: solanaAPIClient,
            realtimeSolanaAccountService: realtimeSolanaAccountService,
            tokensService: tokenService,
            priceService: priceService,
            fiat: "usd",
            proxyConfiguration: .init(address: "", port: 1),
            errorObservable: MockErrorObservable()
        )

        // After 1 second
        try await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertEqual(service.state.value.nativeWallet?.lamports, 0)

        solanaAPIClient.balance = 1000
        XCTAssertEqual(service.state.value.nativeWallet?.lamports, 0)

        solanaAPIClient.balance = 5000

        realtimeSolanaAccountService
            .simulateUpdate(
                SolanaAccount(
                    pubkey: accountStorage.account!.publicKey.base58EncodedString,
                    lamports: 5000,
                    token: .nativeSolana
                )
            )

        // After 2 second
        try await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertEqual(service.state.value.nativeWallet?.lamports, 5000)
    }
}

private struct MockAccountStorage: SolanaAccountStorage {
    var account: SolanaSwift.KeyPair? = try! .init()

    func save(_: SolanaSwift.KeyPair) throws {}
}

private class MockSolanaAPIClient: MockSolanaAPIClientBase {
    var balance: UInt64 = 0

    override func getBalance(account _: String, commitment _: Commitment?) async throws -> UInt64 {
        balance
    }

    override func getTokenAccountsByOwner(
        pubkey _: String,
        params _: OwnerInfoParams?,
        configs _: RequestConfiguration?
    ) async throws -> [TokenAccount<AccountInfo>] {
        []
    }

    override func getMultipleAccounts<T>(pubkeys _: [String]) async throws -> [BufferInfo<T>] where T: BufferLayout {
        []
    }
}
