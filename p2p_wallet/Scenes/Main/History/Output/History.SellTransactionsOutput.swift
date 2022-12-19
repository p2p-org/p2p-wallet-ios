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
        func process(newData: [HistoryItem]) -> [HistoryItem] {
            fatalError()
        }
    }
}
