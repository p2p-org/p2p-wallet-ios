import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func initializeAction(
        state: JupiterSwapState,
        services: JupiterSwapServices,
        swapTokens: [SwapToken],
        routeMap: RouteMap,
        fromToken: SwapToken?
    ) async -> JupiterSwapState {
        do {
            let tokens: (fromToken: SwapToken, toToken: SwapToken)
            if let fromToken, let toToken = autoChooseToToken(for: fromToken, from: swapTokens) {
                tokens = (fromToken, toToken)
            } else if let chosenTokens = autoChoose(swapTokens: swapTokens) {
                tokens = chosenTokens
            } else {
                return .zero(status: .error(reason: .initializationFailed), routeMap: routeMap, swapTokens: swapTokens)
            }

            let priceInfo = try await getPrices(from: tokens.fromToken, to: tokens.toToken, services: services)
        
            let possibleToTokens = getPossibleToTokens(fromTokenMint: tokens.fromToken.address, routeMap: routeMap, swapTokens: swapTokens)

            return .init(
                status: .ready,
                routeMap: routeMap,
                swapTokens: swapTokens,
                amountFrom: 0,
                amountFromFiat: 0,
                amountTo: 0,
                amountToFiat: 0,
                fromToken: tokens.fromToken,
                toToken: tokens.toToken,
                possibleToTokens: possibleToTokens,
                priceInfo: priceInfo ?? .init(fromPrice: 0, toPrice: 0),
                slippage: 50
            )
        } catch {
            return .zero(status: .error(reason: .initializationFailed), routeMap: routeMap, swapTokens: swapTokens)
        }
    }
}
