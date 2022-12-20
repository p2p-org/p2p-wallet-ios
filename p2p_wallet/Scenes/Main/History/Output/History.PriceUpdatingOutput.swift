//
// Created by Giang Long Tran on 19.04.2022.
//

import Foundation
import Resolver
import SolanaSwift
import TransactionParser

extension History {
    /// Update apply exchange rate to transaction to show price information
    class PriceUpdatingOutput: HistoryOutput {
        @Injected private var pricesService: PricesServiceType

        func process(newData: [HistoryItem]) -> [HistoryItem] {
            var items = newData
            for index in 0 ..< items.count {
                items[index] = updatedTransactionWithPrice(item: items[index])
            }
            return items
        }

        private func updatedTransactionWithPrice(
            item: HistoryItem
        ) -> HistoryItem {
            switch item {
            case let .parsedTransaction(transaction):
                guard let price = pricesService.currentPrice(for: transaction.symbol)
                else { return .parsedTransaction(transaction) }

                var transaction = transaction
                let amount = transaction.amount
                transaction.amountInFiat = amount * price.value

                return .parsedTransaction(transaction)
            case let .sellTransaction(transaction):
                return .sellTransaction(transaction) // doesn't need to update
            }
            
        }
    }
}
