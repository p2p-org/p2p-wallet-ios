import Foundation

public protocol SellActionServiceProvider {
    associatedtype Quote: SellActionServiceQuote

    func sellQuote(
        baseCurrencyCode: String,
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        extraFeePercentage: Double
    ) async throws -> Quote
}
