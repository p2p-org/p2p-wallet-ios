@testable import KeyAppBusiness
import XCTest

import Combine
import KeyAppKitCore
import SolanaPricesAPIs
import SolanaSwift

final class SolanaAccountsServiceTests: XCTestCase {
    // Ensure 10 seconds updating
    func testMonitoringByTimer() async throws {
        let solanaAPIClient = MockSolanaAPIClient()

        let service = SolanaAccountsService(
            accountStorage: MockAccountStorage(),
            solanaAPIClient: solanaAPIClient,
            tokensService: MockSolanaTokensRepository(),
            priceService: SolanaPriceService(api: MockSolanaPricesAPI()),
            accountObservableService: MockSolanaAccountsObservableService(),
            fiat: "usd",
            errorObservable: MockErrorObservable()
        )

        // After 1 second
        try await Task.sleep(nanoseconds: 1000000000)
        XCTAssertEqual(service.state.value.nativeWallet?.data.lamports, 0)

        solanaAPIClient.balance = 1000

        XCTAssertEqual(service.state.value.nativeWallet?.data.lamports, 0)

        // After 11 second
        try await Task.sleep(nanoseconds: 14000000000)
        XCTAssertEqual(service.state.value.nativeWallet?.data.lamports, 1000)
    }

    // Ensure updating by observableService
    func testMonitoringByObservableService() async throws {
        let accountStorage = MockAccountStorage()
        let solanaAPIClient = MockSolanaAPIClient()
        let observableService = MockSolanaAccountsObservableService()

        let service = SolanaAccountsService(
            accountStorage: accountStorage,
            solanaAPIClient: solanaAPIClient,
            tokensService: MockSolanaTokensRepository(),
            priceService: SolanaPriceService(api: MockSolanaPricesAPI()),
            accountObservableService: observableService,
            fiat: "usd",
            errorObservable: MockErrorObservable()
        )

        // After 1 second
        try await Task.sleep(nanoseconds: 1000000000)
        XCTAssertEqual(service.state.value.nativeWallet?.data.lamports, 0)

        solanaAPIClient.balance = 1000
        XCTAssertEqual(service.state.value.nativeWallet?.data.lamports, 0)

        solanaAPIClient.balance = 5000

        observableService.allAccountsNotificcationsSubject.send(.init(pubkey: accountStorage.account!.publicKey.base58EncodedString, lamports: 5000))

        // After 2 second
        try await Task.sleep(nanoseconds: 1000000000)
        XCTAssertEqual(service.state.value.nativeWallet?.data.lamports, 5000)
    }
}

private struct MockAccountStorage: SolanaAccountStorage {
    var account: SolanaSwift.KeyPair? = try! .init()

    func save(_ account: SolanaSwift.KeyPair) throws {}
}

private class MockSolanaAPIClient: MockSolanaAPIClientBase {
    var balance: UInt64 = 0

    override func getBalance(account: String, commitment: Commitment?) async throws -> UInt64 {
        balance
    }

    override func getTokenAccountsByOwner(pubkey: String, params: OwnerInfoParams?, configs: RequestConfiguration?) async throws -> [TokenAccount<AccountInfo>] {
        []
    }

    override func getMultipleAccounts<T>(pubkeys: [String]) async throws -> [BufferInfo<T>] where T: BufferLayout {
        []
    }
}

private struct MockSolanaTokensRepository: SolanaTokensRepository {
    func getTokensList(useCache: Bool) async throws -> Set<SolanaSwift.Token> {
        []
    }
}

private struct MockSolanaAccountsObservableService: SolanaAccountsObservableService {
    var isConnected: Bool = true

    func subscribeAccountNotification(account: String) async throws {}

    var allAccountsNotificcationsSubject: PassthroughSubject<SolanaAccountEvent, Never> = .init()

    var allAccountsNotificcationsPublisher: AnyPublisher<SolanaAccountEvent, Never> { allAccountsNotificcationsSubject.eraseToAnyPublisher() }
}
