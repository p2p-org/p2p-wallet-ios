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

    /// Return incomplete transactions
    func incompleteTransactions() async throws -> [Provider.Transaction]
    /// Return transaction by  id
    func transaction(id: String) async throws -> Provider.Transaction
    /// Weather service available
    func isAvailable() async throws -> Bool
}

enum SellActionServiceError: Error {
    case invalidURL
}

public protocol SellActionService {
    func calculateRates() async throws -> Double
    func createSellURL(
        quoteCurrencyCode: String,
        baseCurrencyAmount: Double,
        externalTransactionId: String
    ) throws -> URL
    func saveTransaction() async throws
    func deleteTransaction() async throws
}
