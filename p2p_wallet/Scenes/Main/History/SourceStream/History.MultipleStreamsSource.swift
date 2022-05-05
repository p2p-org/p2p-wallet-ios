//
// Created by Giang Long Tran on 18.04.2022.
//

import Foundation
import RxSwift

extension History {
    /// The class helps to merge many source into one and fetch it like a single source.
    class MultipleStreamSource: HistoryStreamSource {
        /// The list of sources
        private let sources: [HistoryStreamSource]
        private var buffer: [HistoryStreamSource.Result] = []
        private(set) var isEmpty: Bool = false

        init(sources: [HistoryStreamSource]) {
            self.sources = sources
        }

        func first() async throws -> HistoryStreamSource.Result? {
            try await Observable
                .from(sources)
                .flatMap { source -> Observable<HistoryStreamSource.Result?> in
                    Observable.asyncThrowing { () -> HistoryStreamSource.Result? in try await source.first() }
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
