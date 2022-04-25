//
// Created by Giang Long Tran on 18.04.2022.
//

import Foundation

extension History {
    /// The class helps to retrieves all transactions as stream from defined account.
    class AccountStreamSource: HistoryStreamSource {
        let transactionRepository: HistoryTransactionRepository

        /// The object that is responsible for parsing transactions
        let transactionParser: TransactionParser

        /// The account address
        private let account: String

        /// The account's token symbol
        private let symbol: String

        /// The most latest signature of transactions, that has been loaded.
        /// This value will be used as pagination indicator and all next transactions after this one will be loaded.
        private var latestFetchedSignature: String?

        /// Fixed number of transactions that will be requested each time.
        private let batchSize: Int = 10

        init(
            account: String,
            symbol: String,
            transactionRepository: HistoryTransactionRepository,
            transactionParser: TransactionParser
        ) {
            self.account = account
            self.symbol = symbol
            self.transactionRepository = transactionRepository
            self.transactionParser = transactionParser
        }

        func first() async throws -> HistoryStreamSource.Result? {
            guard let signatureInfo = try await transactionRepository.getSignatures(
                address: account,
                limit: batchSize,
                before: latestFetchedSignature
            ).first else { return nil }

            return (signatureInfo, account, symbol)
        }

        func next(configuration: FetchingConfiguration) -> AsyncThrowingStream<HistoryStreamSource.Result, Error> {
            AsyncThrowingStream<HistoryStreamSource.Result, Error> { stream in
                Task {
                    do {
                        while true {
                            // Fetch transaction signatures
                            let signatureInfos = try await transactionRepository.getSignatures(
                                address: account,
                                limit: batchSize,
                                before: latestFetchedSignature
                            )

                            if signatureInfos.isEmpty {
                                stream.finish(throwing: nil)
                                return
                            }

                            // Fetch transaction and parse it
                            for signatureInfo in signatureInfos {
                                // Calculate time
                                var transactionTime = Date()
                                if let time = signatureInfo.blockTime {
                                    transactionTime = Date(timeIntervalSince1970: TimeInterval(time))
                                }

                                if transactionTime >= configuration.timestampEnd {
                                    // Emit transaction
                                    latestFetchedSignature = signatureInfo.signature
                                    stream.yield((signatureInfo, account, symbol))
                                } else {
                                    // Break stream and return
                                    stream.finish(throwing: nil)
                                    return
                                }
                            }
                        }
                    } catch {
                        stream.finish(throwing: error)
                    }
                }
            }
        }

        func reset() { latestFetchedSignature = nil }
    }
}
