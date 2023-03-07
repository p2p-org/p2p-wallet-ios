import XCTest
@testable import Wormhole

final class EthereumPrivateKeyTests: XCTestCase {
    func testValidAddress() throws {
        let phrase = "omit pluck dizzy deer film slender rabbit remember hover magic puppy such"
        let result = try EthereumPrivateKey.init(phrase: phrase)
        XCTAssertEqual(result.publicKey.address.hex(eip55: true), "0x3626Bf5DBC1c2995A843DA62DD35abCB6E1C6D6F")
    }
}
