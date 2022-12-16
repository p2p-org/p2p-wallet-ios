import Combine
import Foundation

public enum SellDataServiceStatus {
    case initialized
    case updating
    case ready
    case error
}

public struct SellDataServiceTransaction {
    var id: String
    var status: Status
    var baseCurrencyAmount: Double
    var quoteCurrencyAmount: Double
    var usdRate: Double
    var eurRate: Double
    var gbpRate: Double
    var depositWallet: String
}

public protocol SellDataService {
    associatedtype Provider: SellDataServiceProvider
    var status: AnyPublisher<SellDataServiceStatus, Never> { get }
    var lastUpdateDate: AnyPublisher<Date, Never> { get }

    /// Request for pendings, rates, min amounts
    func update(id: String) async throws

    /// Supported crypto currencies
    var currency: ProviderCurrency! { get }
    /// Supported Fiat by provider for your region
    var fiat: Fiat! { get }
    /// Return incomplete transactions
    var incompleteTransactions: [SellDataServiceTransaction] { get }
    /// Weather service available
    func isAvailable() async -> Bool
    func deleteTransaction(id: String) async throws
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
}

public protocol SellActionServiceQuote {
    var extraFeeAmount: Double { get }
    var feeAmount: Double { get }
    var baseCurrencyPrice: Double { get }
    var quoteCurrencyAmount: Double { get }
}
