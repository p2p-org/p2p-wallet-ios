import XCTest
@testable import FeeRelayerSwift
import SolanaSwift

class APIClientTests: XCTestCase {
    var feeRelayerAPIClient: FeeRelayerAPIClient!

    override func setUp() async throws {
        feeRelayerAPIClient = APIClient(
            httpClient: FeeRelayerHTTPClient(networkManager: MockNetworkManager()),
            baseUrlString: "",
            version: 1
        )
    }
    
    override func tearDown() async throws {
        feeRelayerAPIClient = nil
    }

    func testGetFeeRelayerPubkey() async throws {
        let result = try await feeRelayerAPIClient.getFeePayerPubkey()
        XCTAssertEqual(result, "HkLNnxTFst1oLrKAJc3w6Pq8uypRnqLMrC68iBP6qUPu")
    }

    func testGetFreeTransactionFeeLimit() async throws {
        let result = try await feeRelayerAPIClient.getFreeFeeLimits(for: "GZpacnxxvtFDMg16KWSH8q2g8tM7fwJvNMkb2Df34h9N")
        XCTAssertEqual(result.authority.count, 32)
        XCTAssertEqual(result.limits.maxTokenAccountCreationCount, 30)
    }

    func testRelayTransaction() async throws {
        let txs = try await feeRelayerAPIClient.sendTransaction(
            .relayTransaction(
                .init(
                    preparedTransaction: mockedTransaction,
                    statsInfo: .init(
                        operationType: .transfer,
                        deviceType: .iOS,
                        currency: "SOL",
                        build: "2.0.0",
                        environment: .dev
                    )
                )
            )
        )
        XCTAssertEqual(txs, "39ihraT1nDRgJbg8owTukvoqJ2cqb84qXGdkjtLbpGuGrgyCpr4F2v57XpvNaJxysEpGWatMFG6zQi6rc91689P2")
    }

    func testSignRelayTransaction() async throws {
        let txs = try await feeRelayerAPIClient.sendTransaction(
            .signRelayTransaction(
                .init(
                    preparedTransaction: mockedTransaction,
                    statsInfo: .init(
                        operationType: .transfer,
                        deviceType: .iOS,
                        currency: "SOL",
                        build: "2.0.0",
                        environment: .dev
                    )
                )
            )
        )
        XCTAssertEqual(txs, "39ihraT1nDRgJbg8owTukvoqJ2cqb84qXGdkjtLbpGuGrgyCpr4F2v57XpvNaJxysEpGWatMFG6zQi6rc91689P2")
    }
}

// MARK: - Mocks

var mockedTransaction: PreparedTransaction {
    .init (
        transaction: .init(
            instructions: [
                try! AssociatedTokenProgram.createAssociatedTokenAccountInstruction(
                    mint: .renBTCMint,
                    owner: "6QuXb6mB6WmRASP2y8AavXh6aabBXEH5ZzrSH5xRrgSm",
                    payer: "HkLNnxTFst1oLrKAJc3w6Pq8uypRnqLMrC68iBP6qUPu"
                )
            ],
            recentBlockhash: "CSymwgTNX1j3E4qhKfJAUE41nBWEwXufoYryPbkde5RR",
            feePayer: "HkLNnxTFst1oLrKAJc3w6Pq8uypRnqLMrC68iBP6qUPu"),
        signers: [],
        expectedFee: .zero
    )
}

private class MockNetworkManager: FeeRelayerSwift.NetworkManager {
    func requestData(request: URLRequest) async throws -> (Data, URLResponse) {
        let mockResponse = [
            "fee_payer/pubkey":
                "HkLNnxTFst1oLrKAJc3w6Pq8uypRnqLMrC68iBP6qUPu",
            "relay_transaction": #"["39ihraT1nDRgJbg8owTukvoqJ2cqb84qXGdkjtLbpGuGrgyCpr4F2v57XpvNaJxysEpGWatMFG6zQi6rc91689P2"]"#,
            "sign_relay_transaction":
                #"{"signature":"39ihraT1nDRgJbg8owTukvoqJ2cqb84qXGdkjtLbpGuGrgyCpr4F2v57XpvNaJxysEpGWatMFG6zQi6rc91689P2","transaction":"<fake transaction>"}"#,
            "free_fee_limits": #"{"authority":[39,247,185,4,85,137,50,166,147,184,221,75,110,103,16,222,41,94,247,132,43,62,172,243,95,204,190,143,153,16,10,197],"limits":{"use_free_fee":true,"max_fee_amount":10000000,"max_fee_count":5,"max_token_account_creation_amount":10000000,"max_token_account_creation_count":30,"max_transaction_lifetime":{"secs":360,"nanos":0},"period":{"secs":86400,"nanos":0},"max_amount":10000000,"max_count":5},"processed_fee":{"total_fee_amount":0,"total_rent_amount":0,"fee_count":0,"rent_count":0,"count":0,"total_amount":0}}"#
        ]
        
        
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        guard let result = mockResponse.first(where: {request.url!.absoluteString.contains($0.key)})
        else {
            fatalError()
        }
        
        return (result.value.data(using: .utf8)!, response)
    }
}
