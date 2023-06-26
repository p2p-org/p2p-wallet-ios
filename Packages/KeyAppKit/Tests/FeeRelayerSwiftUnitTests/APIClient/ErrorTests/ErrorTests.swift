import XCTest
@testable import FeeRelayerSwift

class ErrorTests: XCTestCase, ErrorTestsType {
    func testParsePubkeyError() throws {
        try doTest(
            string: #"{"code": 0, "message": "Wrong hash format \"ABC\": failed to decode string to hash", "data": {"ParsePubkeyError": ["ABC", "Invalid"]}}"#,
            expectedErrorCode: 0,
            expectedMessage: "Wrong hash format \"ABC\": failed to decode string to hash",
            expectedData: .init(type: .parsePubkeyError, data: .init(array: ["ABC", "Invalid"]))
        )
    }
    
    func testTooSmallAmountError() throws {
        try doTest(
            string: #"{"code": 8, "message": "Amount is too small: minimum 10, actual 5", "data": {"TooSmallAmount": {"min": 10, "actual": 5}}}"#,
            expectedErrorCode: 8,
            expectedMessage: "Amount is too small: minimum 10, actual 5",
            expectedData: .init(type: .tooSmallAmount, data: .init(dict: ["min": 10, "actual": 5]))
        )
    }
    
    func testNotEnoughOutAmountError() throws {
        try doTest(
            string: #"{"code": 17, "message": "Not enough output amount: expected 10, actual 5", "data": {"NotEnoughOutAmount": {"expected": 10, "actual": 5}}}"#,
            expectedErrorCode: 17,
            expectedMessage: "Not enough output amount: expected 10, actual 5",
            expectedData: .init(type: .notEnoughOutAmount, data: .init(dict: ["expected": 10, "actual": 5]))
        )
    }
    
    func testUnknownSwapProgramIdError() throws {
        try doTest(
            string: #"{"code": 18, "message": "Unknown Swap program ID: ABC", "data": {"UnknownSwapProgramId": ["ABC"]}}"#,
            expectedErrorCode: 18,
            expectedMessage: "Unknown Swap program ID: ABC",
            expectedData: .init(type: .unknownSwapProgramId, data: .init(array: ["ABC"]))
        )
    }
}
