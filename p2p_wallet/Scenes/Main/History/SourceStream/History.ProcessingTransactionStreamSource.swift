//
// Created by Giang Long Tran on 18.04.2022.
//

import Foundation

extension History {
    /// This class fetches all pending and processing transactions.
    ///
    /// TODO: improve time padding.
    class ProcessingTransactionStreamSource: HistoryStreamSource {
        @Injected private var repository: TransactionHandlerType

        var lastEmittedId: String?

        func next(configuration: FetchingConfiguration) -> AsyncThrowingStream<SolanaSDK.ParsedTransaction, Error> {
            AsyncThrowingStream { stream in
                /// Retrieves processing transactions
                repository.getProcessingTransaction()
                    .filter { transaction in
                        if let transactionTime = transaction.blockTime {
                            // Get all transaction that satisfies configuration
                            return transactionTime >= configuration.timestampEnd
                        }
                        return false
                    }
                    .forEach { transaction in
                        stream.yield(transaction)
                    }

                stream.finish(throwing: nil)
            }
        }

        func first() async throws -> SolanaSDK.ParsedTransaction? {
            repository.getProcessingTransaction().first
        }

        func reset() {}
    }
}
