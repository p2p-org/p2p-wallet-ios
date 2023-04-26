import Foundation

public protocol SellActionService {
    associatedtype Provider: SellActionServiceProvider

    func sellQuote(
        baseCurrencyCode: String,
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        extraFeePercentage: Double
    ) async throws -> Provider.Quote

    func createSellURL(
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        externalCustomerId: String
    ) throws -> URL
}
