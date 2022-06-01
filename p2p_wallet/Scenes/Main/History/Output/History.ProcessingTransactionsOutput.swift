//
// Created by Giang Long Tran on 19.04.2022.
//

import Foundation
import Resolver
import SolanaSwift

extension History {
    /// Combine final list with processing transactions.
    ///
    /// Register a view model with `ProcessingTransactionRefreshTrigger` to shows new incoming transactions.
    class ProcessingTransactionsOutput: HistoryOutput {
        @Injected private var repository: TransactionHandlerType

        func process(newData: [ParsedTransaction]) -> [ParsedTransaction] {
            let transactions = repository.getProcessingTransaction()
                .sorted(by: { $0.blockTime?.timeIntervalSince1970 > $1.blockTime?.timeIntervalSince1970 })

            var data = newData
            for transaction in transactions.reversed() {
                // update if exists and is being processed
                if let index = data.firstIndex(where: { $0.signature == transaction.signature }) {
                    if data[index].status != .confirmed {
                        data[index] = transaction
                    }
                }
                // append if not
                else {
                    if transaction.signature != nil {
                        data.removeAll(where: { $0.signature == nil })
                    }
                    data.insert(transaction, at: 0)
                }
            }
            return data
        }
    }
}
