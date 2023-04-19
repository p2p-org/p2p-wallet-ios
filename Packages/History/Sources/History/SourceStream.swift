//
// Created by Giang Long Tran on 12.04.2022.
//

import Foundation
import Combine
import SolanaSwift

/// The protocol that manages the sequential loading of transaction.
///
/// The ``Result`` type is temporary solution, since the caller need to know more information about transaction (account address or symbol).
/// TODO: Make result more abstract
public protocol HistoryStreamSource {
    /// The result that contains signatureInfo, account and symbol.
    typealias Result = (signatureInfo: SignatureInfo, account: String, symbol: String)

    /// Fetches next single transaction that satisfies the configuration.
    ///
    /// - Parameter configuration: the fetching configuration that contains things like filtering
    /// - Returns: A stream of parsed transactions and the error that can be occurred.
    func next(configuration: FetchingConfiguration) async throws -> Result?

    /// Fetches next sequence of transactions signatures that satisfies the configuration.
    ///
    /// - Parameter configuration: the fetching configuration that contains things like filtering.
    /// - Returns: A current item in stream and move cursor to next item.
    func nextItems(configuration: FetchingConfiguration) async throws -> [Result]

    /// Current item that stream's cursor is holding at current moment.
    ///
    /// - Returns: parsed transaction
    func currentItem() async throws -> Result?

    /// Resets the stream.
    func reset() async
}

public extension HistoryStreamSource {
    /// Fetches all items that satisfy configuration.
    ///
    /// - Parameter configuration: the fetching configuration that contains things like filtering.
    /// - Returns: a full list of transactions.
    func nextItems(configuration: FetchingConfiguration) async throws -> [Result] {
        var sequence: [Result] = []

        while let item = try await next(configuration: configuration), !Task.isCancelled {
            sequence.append(item)
        }

        return sequence
    }
}

/// The configuration that accepted by `next()` method of `StreamSource`.
public struct FetchingConfiguration {
    /// Fetches transactions until this time. If the timestamp of transaction is after it, the stream will be finished.
    let timestampEnd: Date
    
    public init(timestampEnd: Date) {
        self.timestampEnd = timestampEnd
    }
}
