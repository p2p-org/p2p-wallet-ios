//
//  SellTransactionsRepository.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/12/2022.
//

import Foundation
import Combine
import Resolver

/// Repository that control the flow of sell transactions
protocol SellTransactionsRepository: Actor {
    /// Get/Set current fetched transactions
    var transactions: [SellDataServiceTransaction] { get }
    
    /// Set transactions
    func setTransactions(_ transactions: [SellDataServiceTransaction])
    
    /// Delete transactions
    func deleteTransaction(id: String)
}

actor SellTransactionsRepositoryImpl: SellTransactionsRepository {
    
    // MARK: - Properties
    /// Transactions subject
    @Published var transactions: [SellDataServiceTransaction] = []
    
    // MARK: - Methods
    /// Set transactions
    func setTransactions(_ transactions: [SellDataServiceTransaction]) {
        self.transactions = transactions
    }
    
    /// Delete transaction
    func deleteTransaction(id: String) {
        transactions.removeAll(where: {$0.id == id})
    }
}
