import XCTest
@testable import KeyAppBusiness

import Combine
import KeyAppKitCore
import SolanaSwift

final class SolanaAccountsServiceTests: XCTestCase {
    // Ensure 10 seconds updating
    func testMonitoringByTimer() async throws {
        let solanaAPIClient = MockSolanaAPIClient()
        let tokenService = MockTokensRepository()

        let service = SolanaAccountsService(
            accountStorage: MockAccountStorage(),
            solanaAPIClient: solanaAPIClient,
            tokensService: MockSolanaTokensRepository(),
            priceService: PriceService(api: MockSolanaPricesAPI()),
            accountObservableService: MockSolanaAccountsObservableService(),
            fiat: "usd",
            proxyConfiguration: .init(address: "", port: 1),
            errorObservable: MockErrorObservable()
        )

        // After 1 second
        try await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertEqual(service.state.value.nativeWallet?.data.lamports, 0)

        solanaAPIClient.balance = 1000

        XCTAssertEqual(service.state.value.nativeWallet?.data.lamports, 0)

        // After 11 second
        try await Task.sleep(nanoseconds: 14_000_000_000)
        XCTAssertEqual(service.state.value.nativeWallet?.data.lamports, 1000)
    }

    // Ensure updating by observableService
    func testMonitoringByObservableService() async throws {
        let accountStorage = MockAccountStorage()
        let solanaAPIClient = MockSolanaAPIClient()

        let service = SolanaAccountsService(
            accountStorage: accountStorage,
            solanaAPIClient: solanaAPIClient,
            tokensService: MockSolanaTokensRepository(),
            priceService: PriceService(api: MockSolanaPricesAPI()),
            accountObservableService: observableService,
            fiat: "usd",
            proxyConfiguration: .init(address: "", port: 1),
            errorObservable: MockErrorObservable()
        )

        // After 1 second
        try await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertEqual(service.state.value.nativeWallet?.data.lamports, 0)

        solanaAPIClient.balance = 1000
        XCTAssertEqual(service.state.value.nativeWallet?.data.lamports, 0)

        solanaAPIClient.balance = 5000

        observableService.allAccountsNotificcationsSubject
            .send(.init(pubkey: accountStorage.account!.publicKey.base58EncodedString, lamports: 5000))

        // After 2 second
        try await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertEqual(service.state.value.nativeWallet?.data.lamports, 5000)
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
