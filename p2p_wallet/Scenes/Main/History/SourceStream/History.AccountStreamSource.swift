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
        private let accountSymbol: String

        /// The most latest signature of transactions, that has been loaded.
        /// This value will be used as pagination indicator and all next transactions after this one will be loaded.
        private var latestFetchedSignature: String?

        /// Fixed number of transactions that will be requested each time.
        private let batchSize: Int = 10

        init(
            account: String,
            accountSymbol: String,
            transactionRepository: HistoryTransactionRepository,
            transactionParser: TransactionParser
        ) {
            self.account = account
            self.accountSymbol = accountSymbol
            self.transactionRepository = transactionRepository
            self.transactionParser = transactionParser
        }

        func first() async throws -> SolanaSDK.ParsedTransaction? {
            guard let signatureInfo = try await transactionRepository.getSignatures(
                address: account,
                limit: batchSize,
                before: latestFetchedSignature
            ).first else { return nil }

            let transactionInfo = try await transactionRepository.getTransaction(signature: signatureInfo.signature)

            return try await transactionParser.parse(
                signatureInfo: signatureInfo,
                transactionInfo: transactionInfo,
                account: account,
                symbol: accountSymbol
            )
        }

        func next(configuration: FetchingConfiguration) -> AsyncThrowingStream<SolanaSDK.ParsedTransaction, Error> {
            AsyncThrowingStream<SolanaSDK.ParsedTransaction, Error> { stream in
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
                                let signature = signatureInfo.signature

                                // Fetch transaction info
                                let transactionInfo = try await transactionRepository
                                    .getTransaction(signature: signature)

                                // Parse transaction
                                let transaction = try await transactionParser.parse(
                                    signatureInfo: signatureInfo,
                                    transactionInfo: transactionInfo,
                                    account: account,
                                    symbol: accountSymbol
                                )

                                let transactionTime = transaction.blockTime ?? Date()
                                if transactionTime >= configuration.timestampEnd {
                                    // Emit transaction
                                    latestFetchedSignature = signature
                                    stream.yield(transaction)
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
