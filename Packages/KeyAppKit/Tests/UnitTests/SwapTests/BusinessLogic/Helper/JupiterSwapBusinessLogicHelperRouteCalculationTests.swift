import XCTest
@testable import Swap
import SolanaSwift
@testable import Jupiter

class JupiterSwapBusinessLogicHelperRouteCalculationTests: XCTestCase {
    func testWhenAmountIsNilOrZero() async throws {
        // Given
        let preferredRouteId = "route123"
        let amountFrom: Double? = nil // or 0
        let fromTokenMint = "fromToken123"
        let fromTokenDecimals: Decimals = 8
        let toTokenMint = "toToken123"
        let slippageBps = 1000
        let userPublicKey = SystemProgram.id
        let jupiterClient = MockJupiterAPI(
            mockQuoteResult: .init(
                data: [],
                timeTaken: 0,
                contextSlot: nil
            )
        )
        
        // When
        do {
            let _ = try await JupiterSwapBusinessLogic.calculateRoute(
                preferredRouteId: preferredRouteId,
                amountFrom: amountFrom,
                fromTokenMint: fromTokenMint,
                fromTokenDecimals: fromTokenDecimals,
                toTokenMint: toTokenMint,
                slippageBps: slippageBps,
                userPublicKey: userPublicKey,
                jupiterClient: jupiterClient
            )
            // Then
            XCTFail("Expected error to be thrown")
        } catch JupiterSwapError.amountFromIsZero {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testWhenFromAndTokenMintAreEquals() async throws {
        // Given
        let preferredRouteId = "route123"
        let amountFrom: Double = 100
        let fromTokenMint = "sameToken"
        let fromTokenDecimals: Decimals = 8
        let toTokenMint = "sameToken"
        let slippageBps = 1000
        let userPublicKey = SystemProgram.id
        let jupiterClient = MockJupiterAPI(mockQuoteResult: .init(data: [], timeTaken: 0, contextSlot: nil))
        
        // When
        do {
            let _ = try await JupiterSwapBusinessLogic.calculateRoute(
                preferredRouteId: preferredRouteId,
                amountFrom: amountFrom,
                fromTokenMint: fromTokenMint,
                fromTokenDecimals: fromTokenDecimals,
                toTokenMint: toTokenMint,
                slippageBps: slippageBps,
                userPublicKey: userPublicKey,
                jupiterClient: jupiterClient
            )
            // Then
            XCTFail("Expected error to be thrown")
        } catch JupiterSwapError.fromAndToTokenAreEqual {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testIfRoutesResultEmpty() async throws {
        // Given
        let preferredRouteId = "id"
        let amountFrom: Double = 100
        let fromTokenMint = "token1"
        let fromTokenDecimals: Decimals = 8
        let toTokenMint = "token2"
        let slippageBps = 1000
        let userPublicKey = SystemProgram.id
        let jupiterClient = MockJupiterAPI(mockQuoteResult: .init(data: [], timeTaken: 0, contextSlot: nil))
        
        // When
        let result = try await JupiterSwapBusinessLogic.calculateRoute(
            preferredRouteId: preferredRouteId,
            amountFrom: amountFrom,
            fromTokenMint: fromTokenMint,
            fromTokenDecimals: fromTokenDecimals,
            toTokenMint: toTokenMint,
            slippageBps: slippageBps,
            userPublicKey: userPublicKey,
            jupiterClient: jupiterClient
        )
        // Then
        XCTAssertEqual(result.routes, [])
        XCTAssertEqual(result.selectedRoute, nil)
    }
    
    func testIfPreChooseRouteIsStillAvailable() async throws {
        // Given
        let preferredRoute = Route.route(marketInfos: [.marketInfo(index: 2), .marketInfo(index: 3)])
        let preferredRouteId = preferredRoute.id
        let amountFrom: Double = 100
        let fromTokenMint = "token1"
        let fromTokenDecimals: Decimals = 8
        let toTokenMint = "token2"
        let slippageBps = 1000
        let userPublicKey = SystemProgram.id
        let jupiterClient = MockJupiterAPI(mockQuoteResult: .init(data: .mocked, timeTaken: 0, contextSlot: nil))
        
        // When
        let result = try await JupiterSwapBusinessLogic.calculateRoute(
            preferredRouteId: preferredRouteId,
            amountFrom: amountFrom,
            fromTokenMint: fromTokenMint,
            fromTokenDecimals: fromTokenDecimals,
            toTokenMint: toTokenMint,
            slippageBps: slippageBps,
            userPublicKey: userPublicKey,
            jupiterClient: jupiterClient
        )
        // Then
        XCTAssertEqual(result.routes, .mocked)
        XCTAssertEqual(result.selectedRoute, preferredRoute)
    }
    
    func testIfPreChooseRouteIsNotAvailableAnymore() async throws {
        // Given
        let preferredRouteId = "notAvailableAnymoreRoute"
        let amountFrom: Double = 100
        let fromTokenMint = "token1"
        let fromTokenDecimals: Decimals = 8
        let toTokenMint = "token2"
        let slippageBps = 1000
        let userPublicKey = SystemProgram.id
        let jupiterClient = MockJupiterAPI(mockQuoteResult: .init(data: .mocked, timeTaken: 0, contextSlot: nil))
        
        // When
        let result = try await JupiterSwapBusinessLogic.calculateRoute(
            preferredRouteId: preferredRouteId,
            amountFrom: amountFrom,
            fromTokenMint: fromTokenMint,
            fromTokenDecimals: fromTokenDecimals,
            toTokenMint: toTokenMint,
            slippageBps: slippageBps,
            userPublicKey: userPublicKey,
            jupiterClient: jupiterClient
        )
        // Then
        XCTAssertEqual(result.routes, .mocked)
        XCTAssertEqual(result.selectedRoute, [Route].mocked.first)
    }
}

// MARK: - Helpers

private class MockJupiterAPI: MockJupiterAPIBase {
    var mockQuoteResult: Jupiter.Response<[Route]>
    
    init(mockQuoteResult: Jupiter.Response<[Route]>) {
        self.mockQuoteResult = mockQuoteResult
        super.init()
    }
    
    override func quote(
        inputMint: String,
        outputMint: String,
        amount: String,
        swapMode: SwapMode?,
        slippageBps: Int?,
        feeBps: Int?,
        onlyDirectRoutes: Bool?,
        userPublicKey: String?,
        enforceSingleTx: Bool?
    ) async throws -> Jupiter.Response<[Route]> {
        return mockQuoteResult
    }
}

private extension Array where Element == Route {
    static var mocked: Self {
        [
            .route(marketInfos: [.marketInfo(index: 1), .marketInfo(index: 2)]),
            .route(marketInfos: [.marketInfo(index: 2), .marketInfo(index: 3)]),
            .route(marketInfos: [.marketInfo(index: 1), .marketInfo(index: 3)])
        ]
    }
}
