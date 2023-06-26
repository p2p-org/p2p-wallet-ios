import Foundation
import SolanaSwift
@testable import FeeRelayerSwift
import XCTest

class RelayActionTests: XCTestCase {
    fileprivate var accountStorage: MockAccountStorage!

    override func setUp() async throws {
        accountStorage = try await MockAccountStorage()
    }

    override func tearDown() async throws {
        accountStorage = nil
    }

    func testCreateFreeRenBTCAccount() async throws {
//        // Mock services
//        private class MockOrcaSwap: MockOrcaSwapBase {
//
//        }
//
        class MockSolanaAPIClient: MockSolanaAPIClientBase {

        }

        class MockFeeRelayerAPIClient: MockFeeRelayerAPIClientBase {

        }
        
        class CreateRenBTCFeeCalculator: FeeCalculator {
            func calculateNetworkFee(transaction: Transaction) throws -> FeeAmount {
                .zero
            }
        }
//
//        // form service
//        let service = FeeRelayerService(
//            orcaSwap: MockOrcaSwap(),
//            accountStorage: accountStorage,
//            solanaApiClient: MockSolanaAPIClient(),
//            feeRelayerAPIClient: MockFeeRelayerAPIClient(),
//            deviceType: .iOS,
//            buildNumber: "1.0.0"
//        )
        
//        let solanaAPIClient = MockSolanaAPIClient()
//        let feeRelayerAPIClient = MockFeeRelayerAPIClient()
//        
//        // get properties
//        let feePayer = try await feeRelayerAPIClient.getFeePayerPubkey()
//        
//        // form transaction
//        let blockchainClient = BlockchainClient(apiClient: solanaAPIClient)
//        let preparedTransaction = try await blockchainClient.prepareTransaction(
//            instructions: [
//                AssociatedTokenProgram.createAssociatedTokenAccountInstruction(
//                    mint: .renBTCMint,
//                    owner: accountStorage.account!.publicKey,
//                    payer: try PublicKey(string: feePayer)
//                )
//            ],
//            signers: [],
//            feePayer: try PublicKey(string: feePayer),
//            feeCalculator: CreateRenBTCFeeCalculator()
//        )
//
//        XCTAssertEqual(preparedTransaction.expectedFee.total, .zero)
    }
}



//        let freeTransactionFeeLimit = FeeLimitForAuthorityResponse(
//            authority: [],
//            limits: .init(
//                useFreeFee: true,
//                maxAmount: 10000000,
//                maxCount: 100,
//                period: .init(secs: 86400, nanos: 0)
//            ),
//            processedFee: .init(
//                totalAmount: 20000,
//                count: 2
//            )
//        )
