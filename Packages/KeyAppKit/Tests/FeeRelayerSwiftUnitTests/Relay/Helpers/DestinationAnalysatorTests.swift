import Foundation
@testable import FeeRelayerSwift
@testable import SolanaSwift
import XCTest

private let owner: PublicKey = "6QuXb6mB6WmRASP2y8AavXh6aabBXEH5ZzrSH5xRrgSm"
private let usdcAssociatedAddress: PublicKey = "9GQV3bQP9tv7m6XgGMaixxEeEdxtFhwgABw2cxCFZoch"

class DestinationAnalysatorTests: XCTestCase {
    var destinationAnalysator: DestinationAnalysator!
    
    override func tearDown() async throws {
        destinationAnalysator = nil
    }
    
    func testFindRealDestinationWithWSOL() async throws {
        destinationAnalysator = DestinationAnalysatorImpl(solanaAPIClient: MockSolanaAPIClient())
        
        // CASE 1: destination is wsol, needs create temporary wsol account
        let result = try await destinationAnalysator.analyseDestination(
            owner: owner,
            mint: .wrappedSOLMint
        )
        XCTAssertEqual(result, .wsolAccount)
    }
    
    func testFindRealDestinationWithNonGivenDestination() async throws {
        destinationAnalysator = DestinationAnalysatorImpl(solanaAPIClient: MockSolanaAPIClient(testCase: 1))
        
        // CASE 3: given destination is nil, need to return associated address and check for it creation
        let result = try await destinationAnalysator.analyseDestination(
            owner: owner,
            mint: .usdcMint
        )
        
        XCTAssertEqual(result, .splAccount(needsCreation: false))
    }
    
    func testFindRealDestinationWithNonGivenDestination2() async throws {
        destinationAnalysator = DestinationAnalysatorImpl(solanaAPIClient: MockSolanaAPIClient(testCase: 2))
        
        // CASE 3: given destination is nil, need to return associated address and check for it creation
        let result = try await destinationAnalysator.analyseDestination(
            owner: owner,
            mint: .usdcMint
        )
        
        XCTAssertEqual(result, .splAccount(needsCreation: true))
    }
}

private class MockSolanaAPIClient: MockSolanaAPIClientBase {
    private let testCase: Int
    
    init(testCase: Int = 0) {
        self.testCase = testCase
    }
    
    override func getAccountInfo<T>(account: String) async throws -> BufferInfo<T>? where T : BufferLayout {
        switch account {
        case usdcAssociatedAddress.base58EncodedString:
            let info = BufferInfo<AccountInfo>(
                lamports: 0,
                owner: testCase > 1 ? SystemProgram.id.base58EncodedString: TokenProgram.id.base58EncodedString,
                data: .init(mint: SystemProgram.id, owner: SystemProgram.id, lamports: 0, delegateOption: 0, isInitialized: true, isFrozen: true, state: 0, isNativeOption: 0, rentExemptReserve: nil, isNativeRaw: 0, isNative: true, delegatedAmount: 0, closeAuthorityOption: 0),
                executable: false,
                rentEpoch: 0
            )
            return info as? BufferInfo<T>
        case owner.base58EncodedString:
            let info = BufferInfo<EmptyInfo>(
                lamports: 0,
                owner: SystemProgram.id.base58EncodedString,
                data: .init(),
                executable: false,
                rentEpoch: 0
            )
            return info as? BufferInfo<T>
        default:
            return try await super.getAccountInfo(account: account)
        }
    }
}
