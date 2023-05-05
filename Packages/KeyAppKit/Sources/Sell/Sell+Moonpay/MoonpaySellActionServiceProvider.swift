import Foundation
import Moonpay

public class MoonpaySellActionServiceProvider: SellActionServiceProvider {
    public typealias Quote = Moonpay.SellQuote

    private var moonpayAPI: Moonpay.Provider
    
    public init(moonpayAPI: Moonpay.Provider) {
        self.moonpayAPI = moonpayAPI
    }

    public func sellQuote(
        baseCurrencyCode: String,
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        extraFeePercentage: Double = 0
    ) async throws -> Quote {
         try await moonpayAPI.getSellQuote(
            baseCurrencyCode: baseCurrencyCode,
            quoteCurrencyCode: quoteCurrencyCode,
            baseCurrencyAmount: baseCurrencyAmount,
            extraFeePercentage: extraFeePercentage
         )
    }
}
