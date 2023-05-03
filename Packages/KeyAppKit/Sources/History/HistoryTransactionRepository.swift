//
// Created by Giang Long Tran on 15.04.2022.
//

import Foundation
import SolanaSwift

/// The repository that works with transactions.
public protocol HistoryTransactionRepository {
    /// Fetches a list of signatures, that belongs to the `address`.
    ///
    /// - Parameters:
    ///   - address: the account address
    ///   - limit: the number of transactions that will be fetched.
    ///   - before: the transaction signature, that indicates the offset of fetching.
    /// - Returns: the list of `SignatureInfo`
    func getSignatures(address: String, limit: Int, before: String?) async throws -> [SignatureInfo]

    /// Fetch all data of the transaction
    ///
    /// - Parameter signature: The transaction signature
    /// - Returns: `TransactionInfo`, that can be parsed later.
    func getTransaction(signature: String) async throws -> TransactionInfo
}

public class SolanaTransactionRepository: HistoryTransactionRepository {
    private let solanaAPIClient: SolanaAPIClient

    public init(solanaAPIClient: SolanaAPIClient) {
        self.solanaAPIClient = solanaAPIClient
    }

    public func getSignatures(address: String, limit: Int, before: String?) async throws -> [SignatureInfo] {
        try await solanaAPIClient
            .getSignaturesForAddress(address: address, configs: .init(limit: limit, before: before))
    }

    public func getTransaction(signature: String) async throws -> TransactionInfo {
        try await solanaAPIClient.getTransaction(signature: signature, commitment: nil)!
    }

    public func getTransactions(signatures: [String]) async throws -> [TransactionInfo?] {
        let results: [TransactionInfo?] = try await solanaAPIClient.batchRequest(
            method: "getTransaction",
            params: signatures.map { [$0, RequestConfiguration(encoding: "jsonParsed")] }
        )
        return results
    }
}
