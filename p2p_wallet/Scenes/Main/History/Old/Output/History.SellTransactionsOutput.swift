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
import Sell

extension History {
    /// Combine final list with processing transactions.
    ///
    /// Register a view model with `SellTransactionRefreshTrigger` to shows new incoming transactions.
    class SellTransactionsOutput: HistoryOutput {
    
        // MARK: - Dependencies
        @Injected private var sellDataService: any SellDataService
        
        // MARK: - Initializer
    
        func process(newData: [HistoryItem]) -> [HistoryItem] {
            // get transactions
            var transactions = sellDataService.transactions
            
            /// Applies to output list
            var data = newData
            data.removeAll { item in
                switch item {
                case .sellTransaction:
                    return true
                default:
                    return false
                }
            }
            data = transactions.map { HistoryItem.sellTransaction($0) } + data
            return data
        }
    }
}
