import BigDecimal
import Foundation
import KeyAppKitCore

internal enum PriceRuleHandler {
    case next(TokenPrice?)
    case stop(TokenPrice?)
}

internal protocol PriceRule {
    func adjustValue(token: SomeToken, price: TokenPrice, fiat: String) -> PriceRuleHandler
}

// Make price rate equals 1:1 when `ruleOfProcessingTokenPrice` equals `byCountOfTokensValue`.
internal class OneToOnePriceRule: PriceRule {
    func adjustValue(token: SomeToken, price: TokenPrice, fiat _: String) -> PriceRuleHandler {
        if token.keyAppExtension.ruleOfProcessingTokenPriceWS == .byCountOfTokensValue {
            return .next(TokenPrice(currencyCode: price.currencyCode, value: 1.0, token: token))
        }

        return .next(price)
    }
}

// De-noise price by measure percentage difference. If the difference is in allowed range, the value
internal class DeNoisePriceRule: PriceRule {
    func adjustValue(token: SomeToken, price: TokenPrice, fiat _: String) -> PriceRuleHandler {
        if let allowPercentageDifferenceValue = token.keyAppExtension.percentDifferenceToShowByPriceOnWS {
            let percentageDifferenceValue = 100 - (1 / price.value) * 100

            print(percentageDifferenceValue, allowPercentageDifferenceValue)

            if abs(percentageDifferenceValue) <= BigDecimal(floatLiteral: allowPercentageDifferenceValue) {
                return .next(TokenPrice(currencyCode: price.currencyCode, value: 1.0, token: token))
            }
        }

        return .next(price)
    }
}
