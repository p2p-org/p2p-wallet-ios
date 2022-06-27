//
// Created by Giang Long Tran on 18.04.2022.
//

import Foundation
import RxConcurrency
import RxSwift

extension History {
    /// The class that merges many sources into one and represents as single stream of sequential transactions.
    ///
    /// The items can be emits two or more times if transaction belongs to many streams.
    class MultipleStreamSource: HistoryStreamSource {
        /// The list of sources
        private let sources: [HistoryStreamSource]

        /// A stream's buffer of transactions
        private var buffer: [HistoryStreamSource.Result] = []

        init(sources: [HistoryStreamSource]) {
            self.sources = sources
        }

        func currentItem() async throws -> HistoryStreamSource.Result? {
            try await Observable
                .from(sources)
                .flatMap { source -> Observable<HistoryStreamSource.Result?> in
                    Observable.async { () -> HistoryStreamSource.Result? in try await source.currentItem() }
                }
                .reduce(nil) { (mostFirst: HistoryStreamSource.Result?, trx: HistoryStreamSource.Result?) -> HistoryStreamSource.Result? in
                    guard let t1 = trx?.0.blockTime else { return mostFirst }
                    guard let t2 = mostFirst?.0.blockTime else { return trx }
                    if t1 > t2 { return trx }
                    return mostFirst
                }
                .asSingle()
                .value
        }

        func next(configuration: FetchingConfiguration) async throws -> HistoryStreamSource.Result? {
            if buffer.isEmpty { try await fillBuffer(configuration: configuration) }

            guard let item = buffer.first else { return nil }
            buffer.remove(at: 0)
            return item
        }

        /// A method that fills a buffer
        private func fillBuffer(configuration: FetchingConfiguration) async throws {
            try Task.checkCancellation()
            let newResults = try await withThrowingTaskGroup(
                of: [HistoryStreamSource.Result].self,
                returning: [HistoryStreamSource.Result].self
            ) { group in
                for source in sources {
                    group.addTask {
                        try await source.nextItems(configuration: configuration)
                    }
                }

                return try await group.reduce([], +)
            }

            try Task.checkCancellation()
            buffer.append(contentsOf: newResults)
            buffer.sort { left, right in
                guard
                    let leftTime = left.signatureInfo.blockTime,
                    let rightTime = right.signatureInfo.blockTime
                else { return false }
                return leftTime > rightTime
            }
        }

        func reset() async {
            if Task.isCancelled { return }

            buffer = []
            for source in sources {
                await source.reset()
            }
        }
    }
}
