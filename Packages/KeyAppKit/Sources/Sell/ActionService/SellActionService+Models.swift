import Foundation

public enum SellActionServiceError: Error {
    case invalidURL
}

public protocol SellActionServiceQuote {
    var extraFeeAmount: Double { get }
    var feeAmount: Double { get }
    var baseCurrencyPrice: Double { get }
    var quoteCurrencyAmount: Double { get }
}
