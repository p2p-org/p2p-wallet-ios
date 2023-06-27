import Jupiter
import SolanaSwift

public struct JupiterSwapRouteCalculationResult {
    public let routes: [Route]
    public let selectedRoute: Route?
}

extension JupiterSwapBusinessLogic {
    public static func calculateRoute(
        preferredRouteId: String?,
        amountFrom: Double?,
        fromTokenMint: String,
        fromTokenDecimals: Decimals,
        toTokenMint: String,
        slippageBps: Int,
        userPublicKey: PublicKey,
        jupiterClient: JupiterAPI
    ) async throws -> JupiterSwapRouteCalculationResult {
        // get current from amount
        guard let amountFrom, amountFrom > 0
        else {
            throw JupiterSwapError.amountFromIsZero
        }
        
        // assert from token is not equal to toToken
        guard fromTokenMint != toTokenMint else {
            throw JupiterSwapError.fromAndToTokenAreEqual
        }
        
        // get lamport
        let amountFromLamports = amountFrom
            .toLamport(decimals: fromTokenDecimals)
        
        // call api to get routes and amount
        let data = try await jupiterClient.quote(
            inputMint: fromTokenMint,
            outputMint: toTokenMint,
            amount: String(amountFromLamports),
            swapMode: nil,
            slippageBps: slippageBps,
            feeBps: nil,
            onlyDirectRoutes: nil,
            userPublicKey: userPublicKey.base58EncodedString,
            enforceSingleTx: nil
        )
        
        // routes
        let routes = data.data
        
        // if pre chosen route is stil available, choose it
        let route = data.data.first(
            where: {$0.id == preferredRouteId})
        ?? data.data.first // if not choose the first (the best) one
        
        return .init(routes: routes, selectedRoute: route)
    }
}
