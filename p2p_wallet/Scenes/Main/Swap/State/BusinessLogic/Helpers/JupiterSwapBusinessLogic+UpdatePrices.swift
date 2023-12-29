import Foundation
import Resolver
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func updatePrices(
        state: JupiterSwapState,
        services: JupiterSwapServices
    ) async -> JupiterSwapState {
        // get all tokens that involved in the swap and get the price
        var tokens = [TokenMetadata]()
        tokens.append(state.fromToken.token)
        tokens.append(state.toToken.token)

        // get prices of transitive tokens
        let mints = state.route?.getMints() ?? []
        if mints.count > 2 {
            for mint in mints {
                if let token = state.swapTokens.map(\.token).first(where: { $0.mintAddress == mint }) {
                    tokens.append(token)
                }
            }
        }

        guard !tokens.isEmpty else {
            return state
        }

        // Warning: This method should be refactored as we should not take prices directly from API but from
        // PriceService
        let tokensPriceMap =
            ((try? await services.pricesAPI.getPrices(tokens: tokens, fiat: Defaults.fiat.code)) ?? [:])
            .reduce([String: Double]()) { combined, element in
                let value = element.value.doubleValue
                var combined = combined
                combined[element.key.address] = value
                return combined
            }

        return state.modified {
            $0.tokensPriceMap = $0.tokensPriceMap
                .merging(tokensPriceMap, uniquingKeysWith: { _, new in new })
        }
    }
}
