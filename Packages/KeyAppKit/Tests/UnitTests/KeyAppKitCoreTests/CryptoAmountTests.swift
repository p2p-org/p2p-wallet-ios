//
//  File.swift
//
//
//  Created by Giang Long Tran on 25.03.2023.
//

import BigInt
import BigDecimal
import Foundation
import XCTest
@testable import KeyAppKitCore

final class CryptoAmountTests: XCTestCase {
    func testParsingString() throws {
        let amountInput = "10.55"
        let token = EthereumToken()
        let amount = CryptoAmount(floatString: amountInput, token: token)

        XCTAssertEqual(amount?.value, 10_550_000_000_000_000_000)
        XCTAssertEqual(amount?.decimals, token.decimals)
        XCTAssertEqual(amount?.amount, 10.55)
    }

    func testParsingEmptyString() throws {
        let amountInput = ""
        let token = EthereumToken()
        let amount = CryptoAmount(floatString: amountInput, token: token)

        XCTAssertNil(amount)
    }

    func testParsingOverflowDecimalString() throws {
        let amountInput = "10.123456789123456789123456789123456789"
        let token = EthereumToken()
        let amount = CryptoAmount(floatString: amountInput, token: token)

        XCTAssertEqual(amount?.value, 10_123_456_789_123_456_789)
        XCTAssertEqual(amount?.decimals, token.decimals)
        XCTAssertEqual(amount?.amount, try! BigDecimal(fromString: "10.123456789123456789"))
    }

    func testParsingMaxDecimalString() throws {
        let amountInput = "10.123456789123456789"
        let token = EthereumToken()
        let amount = CryptoAmount(floatString: amountInput, token: token)

        XCTAssertEqual(amount?.value, 10_123_456_789_123_456_789)
        XCTAssertEqual(amount?.decimals, token.decimals)
        XCTAssertEqual(amount?.amount, try! BigDecimal(fromString: "10.123456789123456789"))
    }

    func testParsingWithoutDecimalString() throws {
        let amountInput = "123456789123456789"
        let token = EthereumToken()
        let amount = CryptoAmount(floatString: amountInput, token: token)

        XCTAssertEqual(amount?.value, BigUInt(stringLiteral: "123456789123456789000000000000000000"))
        XCTAssertEqual(amount?.decimals, token.decimals)
        XCTAssertEqual(amount?.amount, try! BigDecimal(fromString: "123456789123456789"))
    }

    func testParsingInvalidString() throws {
        let amountInput = "123456789123456789.1231241231.2131241241"
        let token = EthereumToken()
        let amount = CryptoAmount(floatString: amountInput, token: token)

        XCTAssertNil(amount)
    }

    func testSuperLargeString() throws {
        let amountInput = "123456789123456789"
        let token = EthereumToken(name: "Megacoin", symbol: "MGC", decimals: 255, logo: nil, contractType: .native)
        let amount = CryptoAmount(floatString: amountInput, token: token)

        XCTAssertEqual(
            amount?.value,
            BigUInt(
                stringLiteral: "123456789123456789000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            )
        )
        XCTAssertEqual(amount?.decimals, token.decimals)
        XCTAssertEqual(amount?.amount, 0)
    }
}
