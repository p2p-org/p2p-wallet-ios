//
// Created by Giang Long Tran on 15.12.21.
//

import Foundation

private typealias _Error = Error

extension Moonpay {
    enum Error: _Error {
        case message(message: String)
    }

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
    }

    typealias Currencies = [Currency]
    struct Currency: Codable {
        let id, createdAt, updatedAt, type: String
        let name, code: String
        let precision: Int?
        let addressRegex, testnetAddressRegex: String?
        let minAmount: Double?
        let maxAmount: Double?
        let minBuyAmount: Double?
        let supportsAddressTag: Bool?
        let supportsTestMode, isSuspended, isSupportedInUS, isSellSupported: Bool?
        let notAllowedUSStates: [String]?
    }
}
