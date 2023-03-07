import Jupiter
import SolanaSwift
import Resolver

extension JupiterSwapBusinessLogic {
    static func initializeAction(
        state: JupiterSwapState,
        services: JupiterSwapServices,
        account: KeyPair?,
        swapTokens: [SwapToken],
        routeMap: RouteMap,
        fromToken: SwapToken?,
        toToken: SwapToken?
    ) async -> JupiterSwapState {
        // get prices
        let tokensPriceMap = await Resolver.resolve(PricesStorage.self).retrievePrices()
            .reduce([String: Double]()) { combined, element in
                guard let value = element.value.value else { return combined }
                var combined = combined
                combined[element.key] = value
                return combined
            }
        
        // get relay context
        let relayContext = try? await services.relayContextManager.getCurrentContextOrUpdate()
        
        // get tokens
        let tokens: (fromToken: SwapToken, toToken: SwapToken)
        if let fromToken, let toToken {
            tokens = (fromToken, toToken)
        } else if let fromToken, let toToken = autoChooseToToken(for: fromToken, from: swapTokens) {
            tokens = (fromToken, toToken)
        } else if let chosenTokens = autoChoose(swapTokens: swapTokens) {
            tokens = chosenTokens
        } else {
            return .zero.modified {
                $0.account = account
                $0.status = .ready
                $0.tokensPriceMap = tokensPriceMap
                $0.routeMap = routeMap
                $0.swapTokens = swapTokens
                $0.relayContext = relayContext
            }
        }
        
        return .zero.modified {
            $0.status = .ready
            $0.account = account
            $0.routeMap = routeMap
            $0.swapTokens = swapTokens
            $0.tokensPriceMap = tokensPriceMap
            $0.fromToken = tokens.fromToken
            $0.toToken = tokens.toToken
            $0.slippageBps = Int(Defaults.slippage * 100)
            $0.relayContext = relayContext
        }
    }
}
