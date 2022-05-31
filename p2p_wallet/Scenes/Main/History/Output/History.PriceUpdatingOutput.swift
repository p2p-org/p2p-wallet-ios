//
// Created by Giang Long Tran on 19.04.2022.
//

import Foundation
import Resolver
import SolanaSwift

extension History {
    /// Update apply exchange rate to transaction to show price information
    class PriceUpdatingOutput: HistoryOutput {
        @Injected private var pricesService: PricesServiceType

        func process(newData: [ParsedTransaction]) -> [ParsedTransaction] {
            var transactions = newData
            for index in 0 ..< transactions.count {
                transactions[index] = updatedTransactionWithPrice(transaction: transactions[index])
            }
            return transactions
        }

        private func updatedTransactionWithPrice(
            transaction: ParsedTransaction
        ) -> ParsedTransaction {
            guard let price = pricesService.currentPrice(for: transaction.symbol)
            else { return transaction }

            var transaction = transaction
            let amount = transaction.amount
            transaction.amountInFiat = amount * price.value

            return transaction
        }
    }
}
