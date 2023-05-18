//
// Created by Giang Long Tran on 18.04.2022.
//

import Foundation
import SolanaSwift

/// The class that retrieves all sequential transactions as stream from defined account.
public actor AccountStreamSource: HistoryStreamSource {
    let transactionRepository: HistoryTransactionRepository

    /// The account address
    private let account: String

    /// The account's token symbol
    private let symbol: String

    /// The most latest signature of transactions, that has been loaded.
    /// This value will be used as pagination indicator and all next transactions after this one will be loaded.
    private var latestFetchedSignature: String?

    /// Fixed number of transactions that will be requested each time.
    private let batchSize: Int = 100

    /// A stream's buffer size
    private let bufferSize: Int = 100

    /// A stream's buffer
    private var buffer: [SignatureInfo] = []

    /// A indicator that shows emptiness of transaction.
    private(set) var isEmpty: Bool = false

    public init(
        account: String,
        symbol: String,
        transactionRepository: HistoryTransactionRepository
    ) {
        self.account = account
        self.symbol = symbol
        self.transactionRepository = transactionRepository
    }
    
    public func currentItem() async throws -> HistoryStreamSource.Result? {
        if buffer.isEmpty { try await fillBuffer() }

        guard let signatureInfo = buffer.first else { return nil }
        return (signatureInfo, account, symbol)
    }
    
    public func next(configuration: FetchingConfiguration) async throws -> HistoryStreamSource.Result? {
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
        if transactionTime >= configuration.timestampEnd, !Task.isCancelled {
            buffer.remove(at: 0)
            return (signatureInfo, account, symbol)
        }

        return nil
    }

    /// This method fills buffer of transaction.
    private func fillBuffer() async throws {
        if isEmpty { return }

        let newSignatures = try await transactionRepository.getSignatures(
            address: account,
            limit: batchSize,
            before: latestFetchedSignature
        )

        try Task.checkCancellation()

        isEmpty = newSignatures.isEmpty
        latestFetchedSignature = newSignatures.last?.signature ?? latestFetchedSignature
        buffer.append(contentsOf: newSignatures)
    }
    
    public func reset() async {
        buffer = []
        latestFetchedSignature = nil
    }
}
