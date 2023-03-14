import Foundation

extension JupiterSwapBusinessLogic {
    static func mapTokenPrices(
        state: JupiterSwapState,
        services: JupiterSwapServices
    ) async -> [String: Double] {
        // get all tokens that involved in the swap and get the price
        var tokens = [Token]()
        tokens.append(state.fromToken.token)
        tokens.append(state.toToken.token)
        
        // get prices of transitive tokens
        let mints = route.getMints()
        if mints.count > 2 {
            for mint in mints {
                if let token = state.swapTokens.map(\.token).first(where: {$0.address == mint}) {
                    tokens.append(token)
                }
            }
        }
        
        // we won't throw any error here, let the map empty only
        let tokensPriceMap = ((try? await services.pricesAPI.getCurrentPrices(coins: tokens, toFiat: Defaults.fiat.symbol)) ?? [:])
            .reduce([String: Double]()) { combined, element in
                guard let value = element.value?.value else { return combined }
                var combined = combined
                combined[element.key.address] = value
                return combined
            }
        
        // mix new tokensPriceMap to old tokensPriceMap
        let newTokensPriceMap = state.tokensPriceMap
            .merging(tokensPriceMap, uniquingKeysWith: { (_, new) in new })
        
        return newTokensPriceMap
    }
}
