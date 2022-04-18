//
// Created by Giang Long Tran on 15.04.2022.
//

import Foundation

/// The repository that works with transactions.
protocol HistoryTransactionRepository {
    /// Fetches a list of signatures, that belongs to the `address`.
    ///
    /// - Parameters:
    ///   - address: the account address
    ///   - limit: the number of transactions that will be fetched.
    ///   - before: the transaction signature, that indicates the offset of fetching.
    /// - Returns: the list of `SignatureInfo`
    func getSignatures(address: String, limit: Int, before: String?) async throws -> [SolanaSDK.SignatureInfo]

    /// Fetch all data of the transaction
    ///
    /// - Parameter signature: The transaction signature
    /// - Returns: `TransactionInfo`, that can be parsed later.
    func getTransaction(signature: String) async throws -> SolanaSDK.TransactionInfo
}

extension History {
    class SolanaTransactionRepository: HistoryTransactionRepository {
        private let solanaSDK: SolanaSDK

        init(solanaSDK: SolanaSDK) { self.solanaSDK = solanaSDK }

        func getSignatures(address: String, limit: Int, before: String?) async throws -> [SolanaSDK.SignatureInfo] {
            try await solanaSDK
                .getSignaturesForAddress(address: address, configs: .init(limit: limit, before: before))
                .value
        }

        func getTransaction(signature: String) async throws -> SolanaSDK.TransactionInfo {
            try await solanaSDK.getTransaction(transactionSignature: signature).value
        }
    }

    class CachingTransactionRepository: HistoryTransactionRepository, Cachable {
        private static let maxCacheSize = 50

        let delegate: HistoryTransactionRepository

        private let signaturesCache = Utils.InMemoryCache<[SolanaSDK.SignatureInfo]>(maxSize: 50)
        private let transactionCache = Utils.InMemoryCache<SolanaSDK.TransactionInfo>(maxSize: 50)

        init(delegate: HistoryTransactionRepository) { self.delegate = delegate }

        func getTransaction(signature: String) async throws -> SolanaSDK.TransactionInfo {
            // Return from cache
            var transaction: SolanaSDK.TransactionInfo? = transactionCache.read(key: signature)
            if let transaction = transaction { return transaction }

            // Fetch and store in cache
            transaction = try await delegate.getTransaction(signature: signature)
            transactionCache.write(key: signature, data: transaction!)

            return transaction!
        }

        func getSignatures(address: String, limit: Int, before: String?) async throws -> [SolanaSDK.SignatureInfo] {
            let cacheKey = "\(address)-\(limit)-\(before ?? "nil")"

            var signatures = signaturesCache.read(key: cacheKey)
            if let signatures = signatures { return signatures }

            signatures = try await delegate.getSignatures(address: address, limit: limit, before: before)
            signaturesCache.write(key: cacheKey, data: signatures!)
            return signatures!
        }

        func clear() { transactionCache.clear() }
    }
}
