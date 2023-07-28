import KeyAppKitCore
import SolanaSwift
import XCTest
@testable import KeyAppBusiness

final class PriceServiceTests: XCTestCase {
    // Ensure the price service work correctly with lifetime.
    func testLifetimeForSingleToken() async throws {
        // Set 10 seconds lifetime
        let api = MockKeyAppTokenProvider()
        let priceService = PriceServiceImpl(api: api, errorObserver: MockErrorObservable(), lifetime: 10)

        api.tokensPriceResult = [
            .init(
                chainId: "solana",
                data: [
                    .init(address: SolanaToken.nativeSolana.address, price: ["usd": "12.0"]),
                ]
            ),
        ]

        // First fetch
        let immediatlyResult = try await priceService.getPrice(token: SolanaToken.nativeSolana, fiat: "usd")
        XCTAssertEqual(immediatlyResult?.value, 12.0, "The fetched value should correct.")

        api.tokensPriceResult = [
            .init(
                chainId: "solana",
                data: [
                    .init(address: SolanaToken.nativeSolana.address, price: ["usd": "15.0"]),
                ]
            ),
        ]

        // Test after 5 seconds
        try await Task.sleep(nanoseconds: 5_000_000_000)
        let resultAfter5Seconds = try await priceService.getPrice(token: SolanaToken.nativeSolana, fiat: "usd")
        XCTAssertEqual(
            resultAfter5Seconds?.value,
            12.0,
            "The fetched value should be the same after 5 seconds because of caching."
        )

        // Test after 15 seconds
        try await Task.sleep(nanoseconds: 10_000_000_000)
        let resultAfter15Seconds = try await priceService.getPrice(token: SolanaToken.nativeSolana, fiat: "usd")
        XCTAssertEqual(
            resultAfter15Seconds?.value,
            15.0,
            "The fetched value should be the same after 5 seconds because of caching."
        )

        api.tokensPriceResult = []

        // Test after 25 seconds
        try await Task.sleep(nanoseconds: 10_000_000_000)
        let resultAfter25Seconds = try await priceService.getPrice(token: SolanaToken.nativeSolana, fiat: "usd")
        XCTAssertEqual(resultAfter25Seconds?.value, .zero)
    }

//    // Ensure the price service work correctly with lifetime.
//    func testLifetimeForBatchTokens() async throws {
//        // Set 10 seconds lifetime
//        let api = MockSolanaPricesAPI()
//        let priceService = PriceService(api: api, lifetime: 10)
//
//        api.currentPriceResponse = [
//            .nativeSolana: TokenPrice(value: 12.0, change24h: nil),
//            .eth: TokenPrice(value: 55.0, change24h: nil),
//        ]
//
//        // First fetch
//        let immediatlyResult = try await priceService.getPrices(tokens: [.nativeSolana, .eth], fiat: "usd")
//        XCTAssertEqual(immediatlyResult[.nativeSolana]??.value, 12.0)
//        XCTAssertEqual(immediatlyResult[.eth]??.value, 55.0)
//
//        api.currentPriceResponse = [
//            .nativeSolana: TokenPrice(value: 15.0, change24h: nil),
//            .eth: TokenPrice(value: 85.0, change24h: nil),
//        ]
//
//        // Test after 5 seconds
//        try await Task.sleep(nanoseconds: 5_000_000_000)
//        let resultAfter5Seconds = try await priceService.getPrices(tokens: [.nativeSolana, .eth], fiat: "usd")
//        XCTAssertEqual(resultAfter5Seconds[.nativeSolana]??.value, 12.0)
//        XCTAssertEqual(resultAfter5Seconds[.eth]??.value, 55.0)
//
//        // Test after 15 seconds
//        try await Task.sleep(nanoseconds: 10_000_000_000)
//        let resultAfter15Seconds = try await priceService.getPrices(tokens: [.nativeSolana, .eth], fiat: "usd")
//        XCTAssertEqual(resultAfter15Seconds[.nativeSolana]??.value, 15.0)
//        XCTAssertEqual(resultAfter15Seconds[.eth]??.value, 85.0)
//
//        api.currentPriceResponse = [:]
//
//        // Test after 25 seconds
//        try await Task.sleep(nanoseconds: 10_000_000_000)
//        let resultAfter25Seconds = try await priceService.getPrices(tokens: [.nativeSolana, .eth], fiat: "usd")
//        XCTAssertNil(resultAfter25Seconds[.nativeSolana]??.value)
//        XCTAssertNil(resultAfter25Seconds[.eth]??.value)
//    }
}
