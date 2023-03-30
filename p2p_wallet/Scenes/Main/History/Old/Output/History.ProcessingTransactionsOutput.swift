//
// Created by Giang Long Tran on 19.04.2022.
//

import Foundation
import Resolver
import SolanaSwift
import TransactionParser

extension History {
    /// Combine final list with processing transactions.
    ///
    /// Register a view model with `ProcessingTransactionRefreshTrigger` to shows new incoming transactions.
    class ProcessingTransactionsOutput: HistoryOutput {
        /// Filters processing transaction by account address.
        let accountFilter: String?

        init(accountFilter: String?) { self.accountFilter = accountFilter }

        @Injected private var repository: TransactionHandlerType

        func process(newData: [HistoryItem]) -> [HistoryItem] {
            var transactions: [ParsedTransaction]

            // Gets new transactions
            if let accountFilter = accountFilter {
                transactions = repository.getProccessingTransactions(of: accountFilter)
            } else {
                transactions = repository.getProcessingTransaction()
            }

            // Sorts by date
            transactions.sort(by: { $0.blockTime?.timeIntervalSince1970 > $1.blockTime?.timeIntervalSince1970 })

            /// Applies to output list
            var data = newData
            for transaction in transactions.reversed() {
                // update if exists and is being processed
                if let index = data.firstIndex(where: {
                    switch $0 {
                    case .parsedTransaction(let tx):
                        return tx.signature == transaction.signature
                    default:
                        return false
                    }
                }) {
                    switch data[index] {
                    case .parsedTransaction(let transaction):
                        if transaction.status != .confirmed {
                            data[index] = .parsedTransaction(transaction)
                        }
                    default:
                        break
                    }
                }
                // append if not
                else {
                    if transaction.signature != nil {
                        data.removeAll(where: {
                            switch $0 {
                            case .parsedTransaction(let transaction):
                                return transaction.signature == nil
                            default:
                                return false
                            }
                        })
                    }
                    data.insert(.parsedTransaction(transaction), at: 0)
                }
            }
            return data
        }
    }
}
