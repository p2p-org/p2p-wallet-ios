import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func initializeAction(
        state: JupiterSwapState,
        services: JupiterSwapServices,
        swapTokens: [SwapToken],
        routeMap: RouteMap,
        fromToken: SwapToken?,
        toToken: SwapToken?
    ) async -> JupiterSwapState {
        let tokens: (fromToken: SwapToken, toToken: SwapToken)
        if let fromToken, let toToken {
            tokens = (fromToken, toToken)
        } else if let fromToken, let toToken = autoChooseToToken(for: fromToken, from: swapTokens) {
            tokens = (fromToken, toToken)
        } else if let chosenTokens = autoChoose(swapTokens: swapTokens) {
            tokens = chosenTokens
        } else {
            return .zero.modified {
                $0.status = .ready
                $0.routeMap = routeMap
                $0.swapTokens = swapTokens
            }
        }
        
        return .zero.modified {
            $0.status = .ready
            $0.routeMap = routeMap
            $0.swapTokens = swapTokens
            $0.fromToken = tokens.fromToken
            $0.toToken = tokens.toToken
            $0.slippageBps = Int(Defaults.slippage * 100)
        }
    }
}
