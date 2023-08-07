import XCTest
@testable import Onboarding

class E164NumbersTests: XCTestCase {
    func testValidNumber() async throws {
        XCTAssertTrue(E164Numbers.validate("+442071838750"))
    }

    func testInvalidNumber() async throws {
        XCTAssertFalse(E164Numbers.validate("442071838750"))
        XCTAssertFalse(E164Numbers.validate("+14 155 552 67"))
        XCTAssertFalse(E164Numbers.validate("44 207 183 8750"))
    }
}
