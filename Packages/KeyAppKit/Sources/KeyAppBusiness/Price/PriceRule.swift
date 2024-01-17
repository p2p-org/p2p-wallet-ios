import BigDecimal
import Foundation
import KeyAppKitCore

enum PriceRuleHandler {
    case `continue`(TokenPrice?)
    case `break`(TokenPrice?)
}

protocol PriceRule {
    func adjustValue(token: SomeToken, price: TokenPrice, fiat: String) -> PriceRuleHandler
}

// Make price rate equals 1:1 when `ruleOfProcessingTokenPrice` equals `byCountOfTokensValue`.
class OneToOnePriceRule: PriceRule {
    func adjustValue(token _: SomeToken, price: TokenPrice, fiat _: String) -> PriceRuleHandler {
//        if token.keyAppExtension.ruleOfProcessingTokenPriceWS == .byCountOfTokensValue {
//            return .continue(TokenPrice(currencyCode: price.currencyCode, value: 1.0, token: token))
//        }

        .continue(price)
    }
}

// Depegging price by measure percentage difference.
class DepeggingPriceRule: PriceRule {
    func adjustValue(token _: SomeToken, price: TokenPrice, fiat _: String) -> PriceRuleHandler {
//        if let allowPercentageDifferenceValue = token.keyAppExtension.percentDifferenceToShowByPriceOnWS {
//            let percentageDifferenceValue = 100 - (1 / price.value) * 100
//            if abs(percentageDifferenceValue) <= BigDecimal(floatLiteral: allowPercentageDifferenceValue) {
//                return .break(TokenPrice(currencyCode: price.currencyCode, value: 1.0, token: token))
//            } else {
//                return .break(price)
//            }
//        }

        .continue(price)
    }
}
