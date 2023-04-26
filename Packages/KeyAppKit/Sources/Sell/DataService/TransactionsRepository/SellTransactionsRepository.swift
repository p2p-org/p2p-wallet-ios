//
//  SellTransactionsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/12/2022.
//

import Foundation
import Combine

/// Repository that control the flow of sell transactions
public protocol SellTransactionsRepository: Actor {
    /// Get/Set current fetched transactions
    var transactions: [SellDataServiceTransaction] { get }
    
    /// Set transactions
    func setTransactions(_ transactions: [SellDataServiceTransaction])
    
    /// Delete transaction
    func deleteTransaction(id: String)
    
    /// Mark transactionas completed
    func markAsPending(id: String)
}

public actor SellTransactionsRepositoryImpl: SellTransactionsRepository {
    
    // MARK: - Properties

    /// Transactions subject
    @Published public var transactions: [SellDataServiceTransaction] = []
    
    /// Key for storing deletedTransactionIds in UserDefaults
    private static let deletedTransactionIdsKey = "SellTransactionsRepository.deletedTransactionIds"
    
    /// Key for storing completedTransactionIds in UserDefaults
    private static let pendingTransactionIdsKey = "SellTransactionsRepository.pendingTransactionIds"
    
    /// Deleted transactions id
    private var deletedTransactionIds: [String] {
        didSet {
            guard let data = try? JSONEncoder().encode(deletedTransactionIds) else {
                return
            }
            UserDefaults.standard.set(data, forKey: Self.deletedTransactionIdsKey)
        }
    }
    
    /// Completed transactions id
    private var pendingTransactionIds: [String] {
        didSet {
            guard let data = try? JSONEncoder().encode(pendingTransactionIds) else {
                return
            }
            UserDefaults.standard.set(data, forKey: Self.pendingTransactionIdsKey)
        }
    }
    
    // MARK: - Initializer
    public init() {
        // retrieve deleted transaction ids
        if let data = UserDefaults.standard.data(forKey: Self.deletedTransactionIdsKey),
           let array = try? JSONDecoder().decode([String].self, from: data)
        {
            deletedTransactionIds = array
        } else {
            deletedTransactionIds = []
        }
        
        // retrieve completed transaction ids
        if let data = UserDefaults.standard.data(forKey: Self.pendingTransactionIdsKey),
           let array = try? JSONDecoder().decode([String].self, from: data)
        {
            pendingTransactionIds = array
        } else {
            pendingTransactionIds = []
        }
    }
    
    // MARK: - Methods
    /// Set transactions
    public func setTransactions(_ transactions: [SellDataServiceTransaction]) {
        // filter out all deleted transactions
        var transactions = transactions.filter { !deletedTransactionIds.contains($0.id) }
        
        // remap all pending transaction
        transactions = transactions.filter({ transaction in
            transaction.fauilureReason != "Cancelled"
        }).map { transaction in
            guard transaction.status != .completed && transaction.status != .failed
            else {
                return transaction
            }
            var transaction = transaction
            if pendingTransactionIds.contains(transaction.id) {
                transaction.status = .pending
            }
            return transaction
        }
        
        self.transactions = transactions
    }
    
    /// Delete transaction
    public func deleteTransaction(id: String) {
        var transactions = transactions
        transactions.removeAll(where: {$0.id == id})
        self.transactions = transactions
        deletedTransactionIds.append(id)
    }
    
    /// Mark transaction as sent
    public func markAsPending(id: String) {
        guard let index = transactions.firstIndex(where: {$0.id == id}) else {
            return
        }
        var transactions = transactions
        transactions[index].status = .pending
        self.transactions = transactions
        pendingTransactionIds.append(id)
    }
}
