import XCTest
@testable import FeeRelayerSwift

class ClientErrorTests: XCTestCase, ErrorTestsType {
    func testAccountInUseError() throws {
        try doTest(
            string: #"{"code": 6, "message": "Solana RPC client error: Account in use", "data": {"ClientError": ["RpcError"]}}"#,
            expectedErrorCode: 6,
            expectedMessage: "Solana RPC client error: Account in use",
            expectedData: .init(type: .clientError, data: .init(array: ["RpcError"]))
        )
    }
    
    func testInsufficientFundsError() throws {
        // insufficient funds
        let error = try doTest(
            string: ClientError.insufficientFunds,
            expectedErrorCode: 6,
            expectedMessage: "Solana RPC client error: RPC response error -32002: Transaction simulation failed: Error processing Instruction 3: custom program error: 0x1 [37 log messages]",
            expectedData: nil
        )
        
        XCTAssertEqual(error.clientError?.type, .insufficientFunds)
        XCTAssertEqual(error.clientError?.errorLog, "insufficient funds")
        
        // insufficient funds 2
        let error2 = try doTest(
            string: ClientError.insufficientFunds2,
            expectedErrorCode: 6,
            expectedMessage: "Solana RPC client error: RPC response error -32002: Transaction simulation failed: Error processing Instruction 2: custom program error: 0x1 [28 log messages]",
            expectedData: nil
        )
        
        XCTAssertEqual(error2.clientError?.type, .insufficientFunds)
        XCTAssertEqual(error2.clientError?.errorLog, "insufficient lamports 19266, need 2039280")
    }
    
    func testMaxNumberOfInstructionsExceededError() throws {
        // maximum number of instructions allowed
        let error = try doTest(
            string: ClientError.maxNumberOfInstructionsExceeded,
            expectedErrorCode: 6,
            expectedMessage: "Solana RPC client error: RPC response error -32002: Transaction simulation failed: Error processing Instruction 2: Program failed to complete [64 log messages]"
        )
        
        XCTAssertEqual(error.clientError?.type, .maximumNumberOfInstructionsAllowedExceeded)
        XCTAssertEqual(error.clientError?.errorLog, "exceeded maximum number of instructions allowed (1940) at instruction #1675")
    }
    
    func testConnectionClosedBeforeMessageCompletedError() throws {
        // connection closed before message completed
        let error = try doTest(
            string: ClientError.connectionClosedBeforeMessageCompleted,
            expectedErrorCode: 6,
            expectedMessage: "Solana RPC client error: error sending request for url (https://p2p.rpcpool.com/82313b15169cb10f3ff230febb8d): connection closed before message completed"
        )
        
        XCTAssertEqual(error.clientError?.type, .connectionClosedBeforeMessageCompleted)
        XCTAssertEqual(error.clientError?.errorLog, "connection closed before message completed")
    }
    
    func testGivenPoolTokenAmountResultsInZeroTradingTokensError() throws {
        // given pool token amount results in zero trading tokens
        let error = try doTest(
            string: ClientError.givenPoolTokenAmountResultsInZeroTradingTokens,
            expectedErrorCode: 6,
            expectedMessage: "Solana RPC client error: RPC response error -32002: Transaction simulation failed: Error processing Instruction 0: custom program error: 0x14 [10 log messages]"
        )
        
        XCTAssertEqual(error.clientError?.type, .givenPoolTokenAmountResultsInZeroTradingTokens)
        XCTAssertEqual(error.clientError?.errorLog, "Given pool token amount results in zero trading tokens")
    }
    
    func testSwapInstructionExceedsDesiredSlippageLimitError() throws {
        // given pool token amount results in zero trading tokens
        let error = try doTest(
            string: ClientError.swapInstructionExceedsDesiredSlippageLimit,
            expectedErrorCode: 6,
            expectedMessage: "Solana RPC client error: RPC response error -32002: Transaction simulation failed: Error processing Instruction 1: custom program error: 0x10 [26 log messages]"
        )
        
        XCTAssertEqual(error.clientError?.type, .swapInstructionExceedsDesiredSlippageLimit)
        XCTAssertEqual(error.clientError?.errorLog, "Swap instruction exceeds desired slippage limit")
    }
}
