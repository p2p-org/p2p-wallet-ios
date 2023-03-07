//
// Created by Giang Long Tran on 15.12.21.
//

import Foundation

private typealias _Error = Error

extension Moonpay {
    public enum Error: _Error {
        case message(message: String)
    }

    public struct BuyQuote: Codable {
        public let baseCurrencyCode: String
        public let quoteCurrencyCode: String
        public let paymentMethod: String?
        public let feeAmount: Double
        public let extraFeeAmount: Double
        public let networkFeeAmount: Double
        public let totalAmount: Double
        public let baseCurrencyAmount: Double
        public let quoteCurrencyAmount: Double
    }

    public struct SellQuote: Codable {
        public var paymentMethod: String
        public var extraFeeAmount: Double
        public var feeAmount: Double
        public var quoteCurrencyAmount: Double
        public var baseCurrencyAmount: Double
        public var baseCurrencyPrice: Double
        public var baseCurrency: Currency
        public var quoteCurrency: Currency
    }

    public typealias Currencies = [Currency]
    public struct Currency: Codable {
        public let id, createdAt, updatedAt, type: String
        public let name, code: String
        public let precision: Int?
        public let addressRegex, testnetAddressRegex: String?
        public let minAmount: Double?
        public let minSellAmount: Double?
        public let maxSellAmount: Double?
        public let maxAmount: Double?
        public let minBuyAmount: Double?
        public let supportsAddressTag: Bool?
        public let supportsTestMode, isSuspended, isSupportedInUS, isSellSupported: Bool?
        public let notAllowedUSStates: [String]?
    }

    public struct BankTransferAvailability: Codable {
        public var gbp: Bool = false
        public var eur: Bool = false
    }
}
