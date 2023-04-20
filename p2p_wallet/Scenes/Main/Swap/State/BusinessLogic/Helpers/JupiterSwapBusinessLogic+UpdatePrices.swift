import Foundation
import SolanaSwift
import Resolver
import SolanaPricesAPIs

extension JupiterSwapBusinessLogic {
    static func updatePrices(
        state: JupiterSwapState,
        services: JupiterSwapServices
    ) async -> JupiterSwapState {
        // get all tokens that involved in the swap and get the price
        var tokens = [Token]()
        tokens.append(state.fromToken.token)
        tokens.append(state.toToken.token)
        
        // get prices of transitive tokens
        let mints = state.route?.getMints() ?? []
        if mints.count > 2 {
            for mint in mints {
                if let token = state.swapTokens.map(\.token).first(where: {$0.address == mint}) {
                    tokens.append(token)
                }
            }
        }
        
        guard !tokens.isEmpty else {
            return state
        }
        
        let tokensPriceMap = ((try? await services.pricesAPI.getCurrentPrices(coins: tokens, toFiat: Defaults.fiat.code)) ?? [:])
            .reduce([String: Double]()) { combined, element in
                guard let value = element.value?.value else { return combined }
                var combined = combined
                combined[element.key.address] = value
                return combined
            }
        
        return state.modified {
            $0.tokensPriceMap = $0.tokensPriceMap
                .merging(tokensPriceMap, uniquingKeysWith: { (_, new) in new })
        }
    }
}
