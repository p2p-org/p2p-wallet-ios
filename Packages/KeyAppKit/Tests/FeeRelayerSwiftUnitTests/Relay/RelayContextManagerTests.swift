import XCTest
@testable import FeeRelayerSwift
@testable import SolanaSwift

final class RelayContextManagerTests: XCTestCase {
    var contextManager: RelayContextManager!
    fileprivate var feeRelayerAPIClient: MockFeeRelayerAPIClient!
    
    override func setUp() async throws {
        feeRelayerAPIClient = MockFeeRelayerAPIClient()
        contextManager = RelayContextManagerImpl(
            accountStorage: try await MockAccountStorage(),
            solanaAPIClient: MockSolanaAPIClient(),
            feeRelayerAPIClient: feeRelayerAPIClient
        )
    }
    
    override func tearDown() async throws {
        contextManager = nil
        feeRelayerAPIClient = nil
    }
    
    func testUpdate() async throws {
        // First test case, expected context is not nil
        feeRelayerAPIClient.testCase = 0
        try await contextManager.update()
        let context1 = contextManager.currentContext
        XCTAssertNotNil(context1)
        
        // Seconde test case, expected receiving different context
        feeRelayerAPIClient.testCase = 1
        try await contextManager.update()
        let context2 = contextManager.currentContext
        XCTAssertNotNil(context2)
        XCTAssertNotEqual(context1, context2)
        
        // Text case did not change, expected receiving the same context
        try await contextManager.update()
        let context3 = contextManager.currentContext
        XCTAssertNotNil(context3)
        XCTAssertEqual(context2, context3)
    }
    
    func testReplaceContext() async throws {
        // First test case, expected context is not nil
        feeRelayerAPIClient.testCase = 0
        try await contextManager.update()
        let context1 = contextManager.currentContext!
        XCTAssertNotNil(context1)
        
        // Replace
        let replacingContext = RelayContext(
            minimumTokenAccountBalance: context1.minimumRelayAccountBalance + 1,
            minimumRelayAccountBalance: context1.minimumRelayAccountBalance,
            feePayerAddress: SystemProgram.id,
            lamportsPerSignature: context1.lamportsPerSignature,
            relayAccountStatus: context1.relayAccountStatus,
            usageStatus: context1.usageStatus
        )
        contextManager.replaceContext(by: replacingContext)
        XCTAssertNotEqual(context1, contextManager.currentContext)
    }
    
    func testGetCurrentContextOrUpdate() async throws {
        feeRelayerAPIClient.testCase = 0
        let context1 = contextManager.currentContext
        XCTAssertNil(context1)
        let context2 = try await contextManager.getCurrentContextOrUpdate()
        XCTAssertNotEqual(context1, context2)
        let context3 = try await contextManager.getCurrentContextOrUpdate()
        XCTAssertEqual(context2, context3)
    }
}

private class MockSolanaAPIClient: MockSolanaAPIClientBase {
    override func getMinimumBalanceForRentExemption(dataLength: UInt64, commitment: Commitment?) async throws -> UInt64 {
        switch dataLength {
        case 165:
            return 2039280
        case 0:
            return 890880
        default:
            fatalError()
        }
    }
    
    override func getFees(commitment: Commitment?) async throws -> Fee {
        .init(feeCalculator: .init(lamportsPerSignature: 5000), feeRateGovernor: nil, blockhash: nil, lastValidSlot: nil)
    }
    
    override func getAccountInfo<T>(account: String) async throws -> BufferInfo<T>? where T : BufferLayout {
        switch account {
        case PublicKey.relayAccount.base58EncodedString:
            return nil
        default:
            fatalError()
        }
    }
}

private class MockFeeRelayerAPIClient: MockFeeRelayerAPIClientBase {
    var testCase = 0
    
    override func getFeePayerPubkey() async throws -> String {
        "HkLNnxTFst1oLrKAJc3w6Pq8uypRnqLMrC68iBP6qUPu"
    }
    
    override func getFreeFeeLimits(for authority: String) async throws -> FeeLimitForAuthorityResponse {
        let string: String
        
        switch authority {
        case PublicKey.owner.base58EncodedString:
            string = #"{"authority":[39,247,185,4,85,137,50,166,147,184,221,75,110,103,16,222,41,94,247,132,43,62,172,243,95,204,190,143,153,16,10,197],"limits":{"use_free_fee":true,"max_fee_amount":10000000,"max_fee_count":5,"max_token_account_creation_amount":10000000,"max_token_account_creation_count":30,"max_transaction_lifetime":{"secs":360,"nanos":0},"period":{"secs":86400,"nanos":0},"max_amount":10000000,"max_count":5},"processed_fee":{"total_fee_amount":0,"total_rent_amount":0,"fee_count":\#(testCase),"rent_count":0,"count":\#(testCase),"total_amount":0}}"#
        default:
            fatalError()
        }
        
        let feeLimit = try JSONDecoder().decode(FeeLimitForAuthorityResponse.self, from: string.data(using: .utf8)!)
        return feeLimit
    }
}
