//
// Created by Giang Long Tran on 18.04.2022.
//

import Foundation

extension History {
    /// The class helps to retrieves all transactions as stream from defined account.
    actor AccountStreamSource: HistoryStreamSource {
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
        private let batchSize: Int = 15

        private let bufferSize: Int = 15

        private var buffer: [SolanaSDK.SignatureInfo] = []

        private(set) var isEmpty: Bool = false

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
            if buffer.isEmpty { try await fillBuffer() }

            guard let signatureInfo = buffer.first else { return nil }
            return (signatureInfo, account, symbol)
        }

        func next(configuration: FetchingConfiguration) async throws -> HistoryStreamSource.Result? {
            // Fetch transaction signatures
            if buffer.isEmpty { try await fillBuffer() }

            // Fetch transaction and parse it
            guard let signatureInfo = buffer.first else { return nil }

            // Setup transaction timestamp
            var transactionTime = Date()
            if let time = signatureInfo.blockTime {
                transactionTime = Date(timeIntervalSince1970: TimeInterval(time))
            }

            // Check transaction timestamp
            if transactionTime >= configuration.timestampEnd, Task.isNotCancelled {
                buffer.remove(at: 0)
                return (signatureInfo, account, symbol)
            }

            return nil
        }

        private func fillBuffer() async throws {
            if isEmpty { return }

            let newSignatures = try await transactionRepository.getSignatures(
                address: account,
                limit: batchSize,
                before: latestFetchedSignature
            )

            try Task.checkCancellation()

            isEmpty = newSignatures.isEmpty
            latestFetchedSignature = newSignatures.last?.signature
            buffer.append(contentsOf: newSignatures)
        }

        func reset() async {
            buffer = []
            latestFetchedSignature = nil
        }
    }
}
