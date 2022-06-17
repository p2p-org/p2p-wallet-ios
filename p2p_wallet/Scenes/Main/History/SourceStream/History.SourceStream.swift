//
// Created by Giang Long Tran on 12.04.2022.
//

import Foundation

import BECollectionView
import FeeRelayerSwift
import RxSwift
import SolanaSwift

protocol HistoryStreamSource {
    /// The result that contains signatureInfo, account and symbol.
    typealias Result = (signatureInfo: SignatureInfo, account: String, symbol: String)

    /// Fetches new transaction signatures sequencely.
    ///
    /// - Parameter configuration: the fetching configuration that contains things like filtering
    /// - Returns: A stream of parsed transactions and the error that can be occurred.
    func next(configuration: History.FetchingConfiguration) -> AsyncThrowingStream<Result, Error>

    /// Fetch the most earliest transaction.
    ///
    /// - Returns: parsed transaction
    func first() async throws -> Result?

    /// Resets the stream.
    func reset()
}

extension History {
    /// The configuration that accepted by `next()` method of `StreamSource`.
    struct FetchingConfiguration {
        /// Fetches transactions until this time. If the timestamp of transaction is after it, the stream will be finished.
        let timestampEnd: Date
    }
}
