//
// Created by Giang Long Tran on 15.04.2022.
//

import Foundation

protocol HistoryTransactionRepository {
    func getSignatures(address: String, limit: Int, before: String?) async throws -> [SolanaSDK.SignatureInfo]
    func getTransaction(signature: String) async throws -> SolanaSDK.TransactionInfo
}

protocol Cachable {
    func clear()
}

extension History {
    typealias TransactionRepository = HistoryTransactionRepository

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

    class CachingTransactionRepository: TransactionRepository, Cachable {
        private static let maxCacheSize = 50

        let delegate: TransactionRepository

        private let cache = Utils.Cache<SolanaSDK.TransactionInfo>(maxSize: 50)

        init(delegate: TransactionRepository) { self.delegate = delegate }

        func getTransaction(signature: String) async throws -> SolanaSDK.TransactionInfo {
            // Return from cache
            var transaction: SolanaSDK.TransactionInfo? = cache.read(key: signature)
            if let transaction = transaction { return transaction }

            // Fetch and store in cache
            transaction = try await delegate.getTransaction(signature: signature)
            cache.write(key: signature, data: transaction!)

            return transaction!
        }

        func getSignatures(address: String, limit: Int, before: String?) async throws -> [SolanaSDK.SignatureInfo] {
            try await delegate.getSignatures(address: address, limit: limit, before: before)
        }

        func clear() { cache.clear() }
    }
}
