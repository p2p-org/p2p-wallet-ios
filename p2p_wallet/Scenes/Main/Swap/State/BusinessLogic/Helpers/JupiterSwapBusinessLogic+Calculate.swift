import Jupiter
import SolanaSwift
import Resolver
import SolanaPricesAPIs

enum JupiterSwapRouteCalculationError: JupiterSwapError {
    case amountFromIsZero
    case swapToSameToken
    case routeNotFound
    case amountToIsZero
}

struct JupiterSwapRouteCalculationResult {
    let route: Route
    let routes: [Route]
    let amountTo: Double
}

extension JupiterSwapBusinessLogic {
    static func calculateRoute(
        amountFrom: Double?,
        fromToken: Token,
        toToken: Token,
        slippageBps: Int,
        userPublicKey: PublicKey?,
        currentRouteId: String?,
        jupiterClient: JupiterAPI
    ) async throws -> JupiterSwapRouteCalculationResult {
        // get current from amount
        guard let amountFrom, amountFrom > 0
        else {
            throw JupiterSwapRouteCalculationError.amountFromIsZero
        }
        
        // assert from token is not equal to toToken
        guard fromToken.address != toToken.address else {
            throw JupiterSwapRouteCalculationError.swapToSameToken
        }

        // get lamport
        let amountFromLamports = amountFrom
            .toLamport(decimals: fromToken.decimals)
        
        // call api to get routes and amount
        let routes: [Route]
        do {
            routes = try await jupiterClient.quote(
                inputMint: fromToken.address,
                outputMint: toToken.address,
                amount: String(amountFromLamports),
                swapMode: nil,
                slippageBps: slippageBps,
                feeBps: nil,
                onlyDirectRoutes: nil,
                userPublicKey: userPublicKey?.base58EncodedString,
                enforceSingleTx: nil
            ).data
        }
        
        // catch network error and map it to JupiterSwapRouteCalculationError to make sure that only 1 type of error returned
        catch {
            if (error as NSError).isNetworkConnectionError {
                throw JupiterSwapGeneralError.networkError
            }
            throw JupiterSwapGeneralError.unknown
        }
        
        // if pre chosen route is stil available, choose it
        // if not choose the first one
        guard let route = routes.first(
            where: {$0.id == currentRouteId})
                ?? routes.first,
              let amountOut = UInt64(route.outAmount)
        else {
            throw JupiterSwapRouteCalculationError.routeNotFound
        }
        
        return .init(
            route: route,
            routes: routes,
            amountTo: amountOut
                .convertToBalance(decimals: toToken.decimals)
        )
    }
}
