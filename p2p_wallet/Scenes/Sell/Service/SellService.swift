import Combine
import Foundation

enum SellDataServiceStatus {
    case initialized
    case updating
    case ready
    case error(Error)
    
    var isReady: Bool {
        switch self {
        case .ready:
            return true
        default:
            return false
        }
    }
}

public struct SellDataServiceTransaction: Hashable {
    var id: String
    var createdAt: Date?
    var status: Status
    var baseCurrencyAmount: Double
    var quoteCurrencyAmount: Double
    var usdRate: Double
    var eurRate: Double
    var gbpRate: Double
    var depositWallet: String
}

protocol SellDataService {
    associatedtype Provider: SellDataServiceProvider
    
    /// Status of service
    var statusPublisher: AnyPublisher<SellDataServiceStatus, Never> { get }
    
    /// Publisher that emit sell transactions every time when any transaction is updated
    var transactionsPublisher: AnyPublisher<[SellDataServiceTransaction], Never> { get }
    
    /// Get current loaded transactions
    var transactions: [SellDataServiceTransaction] { get }
    
    /// Get current currency
    var currency: Provider.Currency? { get }
    
    /// Get fiat
    var fiat: Fiat? { get }
    
    /// Get userId
    var userId: String? { get }
    
    /// Check if service available
    func isAvailable() async -> Bool
    
    /// Request for pendings, rates, min amounts
    func update() async
    
    /// Retrieve all incompleted transactions
    func updateIncompletedTransactions() async throws
    
    /// Get transaction with id
    func getTransactionDetail(id: String) async throws -> Provider.Transaction
    
    /// Delete transaction from list
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
