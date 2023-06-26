import XCTest
@testable import FeeRelayerSwift

protocol ErrorTestsType: XCTestCase {}

extension ErrorTestsType {
    @discardableResult
    func doTest(
        string: String,
        expectedErrorCode: Int,
        expectedMessage: String,
        expectedData: ErrorDetail? = nil
    ) throws -> FeeRelayerError {
        let data = string.data(using: .utf8)!
        let error = try JSONDecoder().decode(FeeRelayerError.self, from: data)
        XCTAssertEqual(error.code, expectedErrorCode)
        XCTAssertEqual(error.message, expectedMessage)
        if let expectedData = expectedData {
            XCTAssertEqual(error.data, expectedData)
        }
        return error
    }
}
