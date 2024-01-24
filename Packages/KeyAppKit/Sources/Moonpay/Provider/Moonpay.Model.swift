import Foundation

private typealias _Error = Error

public extension Moonpay {
    enum Error: _Error {
        case message(message: String)
    }

    struct BuyQuote: Codable {
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

    struct SellQuote: Codable {
        public var paymentMethod: String
        public var extraFeeAmount: Double
        public var feeAmount: Double
        public var quoteCurrencyAmount: Double
        public var baseCurrencyAmount: Double
        public var baseCurrencyPrice: Double
        public var baseCurrency: Currency
        public var quoteCurrency: Currency
    }

    typealias Currencies = [Currency]
    struct Currency: Codable {
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

    struct BankTransferAvailability: Codable {
        public var gbp: Bool = false
        public var eur: Bool = false
    }

    struct MoonpayCountry: Decodable {
        public let code: String
        public let name: String
        public let alpha3: String
        public let isBuyAllowed: Bool
        public let isSellAllowed: Bool
        public let isNftAllowed: Bool
        public let isAllowed: Bool
        public let states: [State]?

        enum CodingKeys: String, CodingKey {
            case code = "alpha2"
            case name
            case alpha3
            case isBuyAllowed
            case isSellAllowed
            case isNftAllowed
            case isAllowed
            case states
        }

        public struct State: Decodable {
            public let code: String
            public let name: String
            public let isBuyAllowed: Bool
            public let isSellAllowed: Bool
            public let isNftAllowed: Bool
            public let isAllowed: Bool
        }
    }
}
