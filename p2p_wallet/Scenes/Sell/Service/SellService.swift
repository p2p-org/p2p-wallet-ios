import Combine
import Foundation

public enum SellDataServiceStatus {
    case initialized
    case updating
    case ready
    case error
}

public protocol SellDataService {
    associatedtype Provider: SellDataServiceProvider
    var status: AnyPublisher<SellDataServiceStatus, Never> { get }
    var lastUpdateDate: AnyPublisher<Date, Never> { get }

    /// Request for pendings, rates, min amounts
    func update() async throws

    /// Supported crypto currencies
    var currency: ProviderCurrency! { get }
    /// Supported Fiat by provider for your region
    var fiat: Fiat! { get }
    /// Return incomplete transactions
    func incompleteTransactions(transactionId: String) async throws -> [Provider.Transaction]
    /// Return transaction by  id
    func transaction(id: String) async throws -> Provider.Transaction
    /// Weather service available
    func isAvailable() async -> Bool
}

enum SellActionServiceError: Error {
    case invalidURL
}

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
        externalTransactionId: String
    ) throws -> URL

    func saveTransaction() async throws
    func deleteTransaction() async throws
}

public protocol SellActionServiceQuote {
    var extraFeeAmount: Double { get }
    var feeAmount: Double { get }
    var baseCurrencyPrice: Double { get }
    var quoteCurrencyAmount: Double { get }
}
