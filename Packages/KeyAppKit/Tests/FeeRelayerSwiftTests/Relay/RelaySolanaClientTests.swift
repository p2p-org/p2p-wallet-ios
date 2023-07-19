//import XCTest
//@testable import FeeRelayerSwift
//import SolanaSwift
//
//class RelaySolanaClientTests: XCTestCase {
//    var solanaClient: FeeRelayerRelaySolanaClient!
//    override func setUpWithError() throws {
////        solanaClient = SolanaSDK(endpoint: .defaultEndpoints.first!, accountStorage: FakeAccountStorage(seedPhrase: "", network: .mainnetBeta))
//    }
//    
//    func testGetRelayAccountStatusNotYetCreated() async throws {
//        let relayAccount = try FeeRelayer.Relay.Program.getUserRelayAddress(user: "B4PdyoVU39hoCaiTLPtN9nJxy6rEpbciE3BNPvHkCeE2", network: solanaClient.endpoint.network)
//        let result = try await solanaClient.getRelayAccountStatus(relayAccount.base58EncodedString)//.toBlocking().first()!
//        XCTAssertEqual(result, .notYetCreated)
//    }
//    
//    func testGetRelayAccountStatusCreated() async throws {
//        let relayAccount = try FeeRelayer.Relay.Program.getUserRelayAddress(user: "5bYReP8iw5UuLVS5wmnXfEfrYCKdiQ1FFAZQao8JqY7V", network: solanaClient.endpoint.network)
//        let result = try await solanaClient.getRelayAccountStatus(relayAccount.base58EncodedString)//.toBlocking().first()!
//        XCTAssertNotEqual(result, .notYetCreated)
//        XCTAssertNotEqual(result.balance, nil)
//    }
//}
//
