import SolanaSwift
import XCTest
@testable import KeyAppBusiness
@testable import KeyAppKitCore

final class PriceRuleTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAdjustValueWhenRuleIsByCountOfTokensValue() {
        // Given
        let rule = OneToOnePriceRule()
        let token = SomeToken(
            tokenPrimaryKey: .contract(PublicKey.usdcMint.base58EncodedString),
            symbol: "USDC",
            name: "USD Coin",
            decimals: 6,
            network: .solana,
            keyAppExtension: KeyAppTokenExtension(
                ruleOfProcessingTokenPriceWS: .byCountOfTokensValue
            )
        )

        // When
        let result = rule.adjustValue(
            token: token,
            price: TokenPrice(currencyCode: "USD", value: 0.99, token: token),
            fiat: "USD"
        )

        // Then
        switch result {
        case let .continue(newPrice):
            XCTAssertEqual(newPrice?.value, 1.0, "The new price value should be 1.0")
            XCTAssertEqual(newPrice?.currencyCode, "USD", "The new price currency code should match the input")
            XCTAssertTrue(
                newPrice?.token == token,
                "The new price token should be the same instance as the input token"
            )
        case .break:
            XCTFail("Unexpected PriceRuleHandler.break result")
        }
    }

    func testAdjustValueWhenRuleIsNotByCountOfTokensValue() {
        // Given
        let rule = OneToOnePriceRule()
        let token = SomeToken(
            tokenPrimaryKey: .contract(PublicKey.usdcMint.base58EncodedString),
            symbol: "USDC",
            name: "USD Coin",
            decimals: 6,
            network: .solana,
            keyAppExtension: KeyAppTokenExtension()
        )

        // When
        let result = rule.adjustValue(
            token: token,
            price: TokenPrice(currencyCode: "USD", value: 0.99, token: token),
            fiat: "USD"
        )

        // Then
        switch result {
        case let .continue(newPrice):
            XCTAssertEqual(
                newPrice?.value,
                0.99,
                "The new price value should be the same as the input price value"
            )
            XCTAssertEqual(
                newPrice?.currencyCode,
                "USD",
                "The new price currency code should match the input"
            )
            XCTAssertTrue(
                newPrice?.token == token,
                "The new price token should be the same instance as the input token"
            )
        case .break:
            XCTFail("Unexpected PriceRuleHandler.break result")
        }
    }

    func testDepeggingPriceRuleCase1() {
        // Given
        let rule = DepeggingPriceRule()
        let token = SomeToken(
            tokenPrimaryKey: .contract(PublicKey.usdcMint.base58EncodedString),
            symbol: "USDC",
            name: "USD Coin",
            decimals: 6,
            network: .solana,
            keyAppExtension: KeyAppTokenExtension(
                percentDifferenceToShowByPriceOnWS: 2.0
            )
        )

        // When
        let result = rule.adjustValue(
            token: token,
            price: TokenPrice(currencyCode: "USD", value: 0.99, token: token),
            fiat: "USD"
        )

        // Then
        switch result {
        case let .continue(newPrice):
            XCTAssertEqual(
                newPrice?.value,
                1,
                "The new price value should be adjusted"
            )
            XCTAssertEqual(
                newPrice?.currencyCode,
                "USD",
                "The new price currency code should match the input"
            )
            XCTAssertTrue(
                newPrice?.token == token,
                "The new price token should be the same instance as the input token"
            )
        case .break:
            XCTFail("Unexpected PriceRuleHandler.break result")
        }
    }

    func testDepeggingPriceRuleCase2() {
        // Given
        let rule = DepeggingPriceRule()
        let token = SomeToken(
            tokenPrimaryKey: .contract(PublicKey.usdcMint.base58EncodedString),
            symbol: "USDC",
            name: "USD Coin",
            decimals: 6,
            network: .solana,
            keyAppExtension: KeyAppTokenExtension(
                percentDifferenceToShowByPriceOnWS: 2.0
            )
        )

        // When
        let result = rule.adjustValue(
            token: token,
            price: TokenPrice(currencyCode: "USD", value: 0.981, token: token),
            fiat: "USD"
        )

        // Then
        switch result {
        case let .continue(newPrice):
            XCTAssertEqual(
                newPrice?.value,
                1,
                "The new price value should be adjusted"
            )
            XCTAssertEqual(
                newPrice?.currencyCode,
                "USD",
                "The new price currency code should match the input"
            )
            XCTAssertTrue(
                newPrice?.token == token,
                "The new price token should be the same instance as the input token"
            )
        case .break:
            XCTFail("Unexpected PriceRuleHandler.break result")
        }
    }

    func testDepeggingPriceRuleCase3() {
        // Given
        let rule = DepeggingPriceRule()
        let token = SomeToken(
            tokenPrimaryKey: .contract(PublicKey.usdcMint.base58EncodedString),
            symbol: "USDC",
            name: "USD Coin",
            decimals: 6,
            network: .solana,
            keyAppExtension: KeyAppTokenExtension(
                percentDifferenceToShowByPriceOnWS: 2.0
            )
        )

        // When
        let result = rule.adjustValue(
            token: token,
            price: TokenPrice(currencyCode: "USD", value: 0.98, token: token),
            fiat: "USD"
        )

        // Then
        switch result {
        case let .continue(newPrice):
            XCTAssertEqual(
                newPrice?.value,
                0.98,
                "The new price value should be adjusted"
            )
            XCTAssertEqual(
                newPrice?.currencyCode,
                "USD",
                "The new price currency code should match the input"
            )
            XCTAssertTrue(
                newPrice?.token == token,
                "The new price token should be the same instance as the input token"
            )
        case .break:
            XCTFail("Unexpected PriceRuleHandler.break result")
        }
    }

    func testDepeggingPriceRuleCase4() {
        // Given
        let rule = DepeggingPriceRule()
        let token = SomeToken(
            tokenPrimaryKey: .contract(PublicKey.usdcMint.base58EncodedString),
            symbol: "USDC",
            name: "USD Coin",
            decimals: 6,
            network: .solana,
            keyAppExtension: KeyAppTokenExtension(
                percentDifferenceToShowByPriceOnWS: 2.0
            )
        )

        // When
        let result = rule.adjustValue(
            token: token,
            price: TokenPrice(currencyCode: "USD", value: 0.97, token: token),
            fiat: "USD"
        )

        // Then
        switch result {
        case let .continue(newPrice):
            XCTAssertEqual(
                newPrice?.value,
                0.97,
                "The new price value should not be adjusted"
            )
            XCTAssertEqual(
                newPrice?.currencyCode,
                "USD",
                "The new price currency code should match the input"
            )
            XCTAssertTrue(
                newPrice?.token == token,
                "The new price token should be the same instance as the input token"
            )
        case .break:
            XCTFail("Unexpected PriceRuleHandler.break result")
        }
    }
}
