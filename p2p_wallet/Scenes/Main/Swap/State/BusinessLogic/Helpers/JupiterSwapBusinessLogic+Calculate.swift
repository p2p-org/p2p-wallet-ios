import Jupiter
import SolanaSwift
import Resolver
import SolanaPricesAPIs

enum JupiterSwapGeneralError: Swift.Error {
    case networkError
    case unknown
}

enum JupiterSwapRouteCalculationError: Swift.Error {
    case amountFromIsZero
    case swapToSameToken
    case routeNotFound
}

extension JupiterSwapBusinessLogic {
    static func calculateRoute(
        state: JupiterSwapState,
        services: JupiterSwapServices
    ) async throws -> JupiterSwapState {
        // get current from amount
        guard let amountFrom = state.amountFrom, amountFrom > 0
        else {
            throw JupiterSwapRouteCalculationError.amountFromIsZero
        }
        
        // assert from token is not equal to toToken
        guard state.fromToken.address != state.toToken.address else {
            throw JupiterSwapRouteCalculationError.swapToSameToken
        }

        // get lamport
        let amountFromLamports = amountFrom
            .toLamport(decimals: state.fromToken.token.decimals)
        
        // call api to get routes and amount
        do {
            let data = try await services.jupiterClient.quote(
                inputMint: state.fromToken.address,
                outputMint: state.toToken.address,
                amount: String(amountFromLamports),
                swapMode: nil,
                slippageBps: state.slippageBps,
                feeBps: nil,
                onlyDirectRoutes: nil,
                userPublicKey: state.account?.publicKey.base58EncodedString,
                enforceSingleTx: nil
            )
        }
        
        // catch network error and map it to JupiterSwapRouteCalculationError to make sure that only 1 type of error returned
        catch {
            if (error as NSError).isNetworkConnectionError {
                throw JupiterSwapGeneralError.networkError
            }
            throw JupiterSwapGeneralError.unknown
        }
        
        
        // routes
        let routes = data.data
        
        // if pre chosen route is stil available, choose it
        // if not choose the first one
        guard let route = data.data.first(
            where: {$0.id == state.route?.id})
                ?? data.data.first
        else {
            throw JupiterSwapRouteCalculationError.routeNotFound
        }
        
        return state.modified {
            $0.route = route
            $0.routes = routes
            $0.amountTo = UInt64(route.outAmount)?
                .convertToBalance(decimals: state.toToken.token.decimals)
        }
    }
}
