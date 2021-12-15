//
// Created by Giang Long Tran on 15.12.21.
//

import Foundation

extension Moonpay {
    struct BuyQuote: Codable {
        let baseCurrencyCode: String
        let quoteCurrencyCode: String
        let paymentMethod: String?
        
        let feeAmount: Double
        let extraFeeAmount: Double
        let networkFeeAmount: Double
        let totalAmount: Double
        let baseCurrencyAmount: Double
        let quoteCurrencyAmount: Double
        
        static func empty() -> BuyQuote {
            BuyQuote(
                baseCurrencyCode: "",
                quoteCurrencyCode: "",
                paymentMethod: "",
                feeAmount: 0,
                extraFeeAmount: 0,
                networkFeeAmount: 0,
                totalAmount: 0,
                baseCurrencyAmount: 0,
                quoteCurrencyAmount: 0)
        }
    }
}
