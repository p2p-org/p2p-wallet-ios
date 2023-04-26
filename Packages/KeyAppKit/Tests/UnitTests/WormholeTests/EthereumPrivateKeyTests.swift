import XCTest
@testable import Wormhole
import Web3

final class EthereumPrivateKeyTests: XCTestCase {
//    func testValidAddress() throws {
//        let phrase = "omit pluck dizzy deer film slender rabbit remember hover magic puppy such"
//        let result = try EthereumPrivateKey.init(phrase: phrase)
//        XCTAssertEqual(result.publicKey.address.hex(eip55: true), "0x3626Bf5DBC1c2995A843DA62DD35abCB6E1C6D6F")
//    }

    func testPrivateKeyInitialization() throws {
        let privateKey = try EthereumPrivateKey()
        XCTAssertNotNil(privateKey.rawPrivateKey)
        XCTAssertNotNil(privateKey.publicKey)
        XCTAssertNotNil(privateKey.address)
    }

    func testPrivateKeyFromBytes() throws {
        let bytes: Bytes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]
        let privateKey = try EthereumPrivateKey(bytes)
        XCTAssertEqual(privateKey.rawPrivateKey, bytes)
    }

    func testPrivateKeyFromMalformedBytes() {
        let bytes: Bytes = [1, 2, 3]
        XCTAssertThrowsError(try EthereumPrivateKey(bytes)) { error in
            XCTAssertEqual(error as? EthereumPrivateKey.Error, EthereumPrivateKey.Error.keyMalformed)
        }
    }

    func testPrivateKeyVerification() throws {
        let bytes: Bytes = [79, 156, 5, 155, 179, 34, 91, 192, 143, 33, 198, 45, 225, 166, 83, 20, 55, 99, 137, 206, 79, 174, 121, 86, 110, 212, 103, 132, 29, 212, 107, 94]
        XCTAssertNoThrow(try EthereumPrivateKey(bytes))
    }

    func testPrivateKeyVerificationFailure() {
        let bytes: Bytes = [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]
        XCTAssertThrowsError(try EthereumPrivateKey(bytes)) { error in
            XCTAssertEqual(error as? EthereumPrivateKey.Error, EthereumPrivateKey.Error.keyMalformed)
        }
    }
}
