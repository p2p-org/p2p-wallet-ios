//
// Created by Giang Long Tran on 15.04.2022.
//

import Foundation
import Resolver
import SolanaSwift

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
    func getTransaction(signature: String) async throws -> TransactionInfo
}

extension History {
    class SolanaTransactionRepository: HistoryTransactionRepository {
        @Injected private var solanaSDK: SolanaSDK

        func getSignatures(address: String, limit: Int, before: String?) async throws -> [SolanaSDK.SignatureInfo] {
            try await solanaSDK
                .getSignaturesForAddress(address: address, configs: .init(limit: limit, before: before))
                .value
        }

        func getTransaction(signature: String) async throws -> TransactionInfo {
            try await solanaSDK.getTransaction(transactionSignature: signature).value
        }
    }

    class CachingTransactionRepository: HistoryTransactionRepository {
        private static let maxCacheSize = 50

        let delegate: HistoryTransactionRepository

        private let signaturesCache = Utils.InMemoryCache<[SolanaSDK.SignatureInfo]>(maxSize: 50)
        private let transactionCache = Utils.InMemoryCache<TransactionInfo>(maxSize: 50)

        init(delegate: HistoryTransactionRepository) { self.delegate = delegate }

        func getTransaction(signature: String) async throws -> TransactionInfo {
            // Return from cache
            var transaction: TransactionInfo? = await transactionCache.read(key: signature)
            if let transaction = transaction { return transaction }

            // Fetch and store in cache
            transaction = try await delegate.getTransaction(signature: signature)
            await transactionCache.write(key: signature, data: transaction!)

            return transaction!
        }

        func getSignatures(address: String, limit: Int, before: String?) async throws -> [SolanaSDK.SignatureInfo] {
            let cacheKey = "\(address)-\(limit)-\(before ?? "nil")"

            var signatures = await signaturesCache.read(key: cacheKey)
            if let signatures = signatures { return signatures }

            signatures = try await delegate.getSignatures(address: address, limit: limit, before: before)
            await signaturesCache.write(key: cacheKey, data: signatures!)
            return signatures!
        }
    }
}
