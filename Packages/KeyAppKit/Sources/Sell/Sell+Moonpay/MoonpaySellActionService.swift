import Foundation

public class MoonpaySellActionService: SellActionService {
    public typealias Provider = MoonpaySellActionServiceProvider
    
    private let endpoint: String
    private let apiKey: String
    private var provider: Provider
    private let refundWalletAddress: String

    public init(
        provider: Provider,
        refundWalletAddress: String,
        endpoint: String,
        apiKey: String
    ) {
        self.provider = provider
        self.refundWalletAddress = refundWalletAddress
        self.endpoint = endpoint
        self.apiKey = apiKey
    }

    public func sellQuote(
        baseCurrencyCode: String,
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        extraFeePercentage: Double
    ) async throws -> Provider.Quote {
        try await provider.sellQuote(
            baseCurrencyCode: baseCurrencyCode,
            quoteCurrencyCode: quoteCurrencyCode,
            baseCurrencyAmount: baseCurrencyAmount
        )
    }

    public func createSellURL(
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        externalCustomerId: String
    ) throws -> URL {
        var components = URLComponents(string: endpoint + "sell")!
        components.queryItems = [
            .init(name: "apiKey", value: apiKey),
            .init(name: "baseCurrencyCode", value: "sol"),
            .init(name: "refundWalletAddress", value: refundWalletAddress),
            .init(name: "quoteCurrencyCode", value: quoteCurrencyCode),
            .init(name: "baseCurrencyAmount", value: baseCurrencyAmount.toString()),
            .init(name: "externalCustomerId", value: externalCustomerId)
        ]

        guard let url = components.url else {
            throw SellActionServiceError.invalidURL
        }
        return url
    }

    func saveTransaction() async throws {}
    func deleteTransaction() async throws {}
}
