@testable import Wormhole
import XCTest

final class EthereumAddressTests: XCTestCase {
    func testValidAddress() throws {
        let result = EthereumAddressValidation.validate("0xff096cc01a7cc98ae3cd401c1d058baf991faf76")
        XCTAssertTrue(result, "Eth address should be valid")
    }

    func testInValidAddressWithoutPrefix() throws {
        let result = EthereumAddressValidation.validate("ff096cc01a7cc98ae3cd401c1d058baf991faf76")
        XCTAssertFalse(result, "Eth address should be invalid")
    }

    func testInValidAddressMissingCharacter() throws {
        let result = EthereumAddressValidation.validate("ff096cc01a7cc98ae3cd401c1d058baf991faf7")
        XCTAssertFalse(result, "Eth address should be invalid")
    }
}
