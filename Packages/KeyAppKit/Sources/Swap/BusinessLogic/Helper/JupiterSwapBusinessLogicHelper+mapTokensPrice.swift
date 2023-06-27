import Foundation
import Jupiter
import SolanaSwift
import SolanaPricesAPIs

extension JupiterSwapBusinessLogicHelper {
    static func mapTokensPrice(
        currentTokensPriceMap: [String: Double],
        tokensList: [Token],
        selectedRoute: Route,
        fiatCode: String,
        pricesAPI: SolanaPricesAPI
    ) async throws -> [String: Double] {
        // get all mints
        let mints = selectedRoute.getMints()
        
        // get all tokens
        let tokens = tokensList.filter { mints.contains($0.address) }
        
        // get prices
        let tokensPriceMap = ((try? await pricesAPI.getCurrentPrices(coins: tokens, toFiat: fiatCode)) ?? [:])
            .reduce([String: Double]()) { combined, element in
                guard let value = element.value?.value else { return combined }
                var combined = combined
                combined[element.key.address] = value
                return combined
            }
        
        // merge with current priceMap
        return currentTokensPriceMap
            .merging(tokensPriceMap, uniquingKeysWith: { (_, new) in new })
    }
}
