import Combine
import Foundation

public protocol SellDataService {
    associatedtype Provider: SellDataServiceProvider
    
    /// Availability status
    var isAvailable: Bool { get }
    
    /// Status of service
    var statusPublisher: AnyPublisher<SellDataServiceStatus, Never> { get }
    
    /// Publisher that emit sell transactions every time when any transaction is updated
    var transactionsPublisher: AnyPublisher<[SellDataServiceTransaction], Never> { get }
    
    /// Get current loaded transactions
    var transactions: [SellDataServiceTransaction] { get }
    
    /// Get current currency
    var currency: Provider.Currency? { get }
    
    /// Get fiat
    var fiat: Provider.Fiat? { get }
    
    /// Get userId
    var userId: String { get }
    
    /// Check if service available
    func checkAvailability() async
    
    /// Request for pendings, rates, min amounts
    func update() async
    
    /// Retrieve all incompleted transactions
    func updateIncompletedTransactions() async throws
    
    /// Get transaction with id
    func getTransactionDetail(id: String) async throws -> Provider.Transaction
    
    /// Delete transaction from list
    func deleteTransaction(id: String) async throws
    
    /// Mark transaction as pending
    func markAsPending(id: String) async
}
