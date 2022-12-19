//
//  History.SellTransactionsOutput.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/12/2022.
//

import Foundation
import Resolver
import SolanaSwift
import TransactionParser

extension History {
    /// Combine final list with processing transactions.
    ///
    /// Register a view model with `SellTransactionRefreshTrigger` to shows new incoming transactions.
    class SellTransactionsOutput: HistoryOutput {
    
        // MARK: - Dependencies
        @Injected private var sellTransactionsRepository: SellTransactionsRepository
        
        // MARK: - Initializer
    
        func process(newData: [HistoryItem]) -> [HistoryItem] {
            // get transactions
            var transactions = sellTransactionsRepository.currentTransactions
            
            // sort first
            transactions.sort(by: { $0.createdAt?.timeIntervalSince1970 > $1.createdAt?.timeIntervalSince1970 })
            
            /// Applies to output list
            var data = newData
            for transaction in transactions.reversed() {
                // update if exists
                if let index = data.firstIndex(where: {
                    switch $0 {
                    case .sellTransaction(let transaction):
                        return transaction.id == transaction.id
                    default:
                        return false
                    }
                }) {
                    switch data[index] {
                    case .sellTransaction(let transaction):
                        data[index] = .sellTransaction(transaction)
                    default:
                        break
                    }
                }
                // append if not
                else {
                    data.insert(.sellTransaction(transaction), at: 0)
                }
            }
            return data
        }
    }
}
