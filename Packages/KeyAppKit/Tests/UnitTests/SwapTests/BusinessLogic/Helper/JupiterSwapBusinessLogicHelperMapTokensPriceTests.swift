import Foundation
import XCTest
import SolanaSwift
import Jupiter
import SolanaPricesAPIs
@testable import Swap

class JupiterSwapBusinessLogicHelperMapTokensPriceTests: XCTestCase {
    
    func testMapTokensPrice() async throws {
        // Prepare test data
        let currentTokensPriceMap: [String: Double] = [
            Token.nativeSolana.address: 100.0,
            Token.srm.address: 0.03,
            "testMint": 1.001
        ]
        let tokensList: [Token] = [
            .nativeSolana,
            .usdt,
            .usdc,
            .srm
        ]
        
        let selectedRoute = Route.route(
            marketInfos: [
                .marketInfo(index: 1, inputMint: "SOL", outputMint: "USDC"),
                .marketInfo(index: 2, inputMint: "USDC", outputMint: "USDT"),
                .marketInfo(index: 3, inputMint: "USDT", outputMint: "SRM")
            ]
        )
        let fiatCode = "USD"
        
        // Prepare mock pricesAPI
        let mockPricesAPI = MockSolanaPricesAPI()
        
        // Call function and check result
        let result = try await JupiterSwapBusinessLogicHelper.mapTokensPrice(
            currentTokensPriceMap: currentTokensPriceMap,
            tokensList: tokensList,
            selectedRoute: selectedRoute,
            fiatCode: fiatCode,
            pricesAPI: mockPricesAPI
        )
        
        XCTAssertEqual(result, [
            Token.nativeSolana.address: 20,
            Token.usdt.address: 1.02,
            Token.usdc.address: 0.9999,
            Token.srm.address: 0.04,
            "testMint": 1.001
        ])
    }
}

private class MockSolanaPricesAPI: MockSolanaPricesAPIBase {
    override func getCurrentPrices(coins: [Token], toFiat fiat: String) async throws -> [Token : CurrentPrice?] {
        let mockTokenPrices: [Token : CurrentPrice?] = [
            .nativeSolana: .init(value: 20),
            .usdc: .init(value: 0.9999),
            .usdt: .init(value: 1.02),
            .srm: .init(value: 0.04)
        ]
        
        return mockTokenPrices
    }
}
