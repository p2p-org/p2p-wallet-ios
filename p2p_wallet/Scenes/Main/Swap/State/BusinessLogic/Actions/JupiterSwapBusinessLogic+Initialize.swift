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
            if let fromToken {
                tokens = (fromToken, try autoChooseToToken(for: fromToken, from: swapTokens))
            } else {
                tokens = try autoChoose(swapTokens: swapTokens)
            }

            let priceInfo = try await getPrices(from: tokens.fromToken, to: tokens.toToken, services: services)

            return .init(
                status: .ready,
                routeMap: routeMap,
                swapTokens: swapTokens,
                amountFrom: 0,
                amountFromFiat: 0,
                amountTo: 0,
                fromToken: tokens.fromToken,
                toToken: tokens.toToken,
                priceInfo: priceInfo ?? .init(fromPrice: 0, toPrice: 0),
                slippage: 50
            )
        } catch {
            return .zero(status: .error(reason: .initializationFailed), routeMap: routeMap, swapTokens: swapTokens)
        }
    }
}
