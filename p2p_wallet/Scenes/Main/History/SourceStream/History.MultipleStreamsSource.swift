//
// Created by Giang Long Tran on 18.04.2022.
//

import Foundation
import RxConcurrency
import RxSwift

extension History {
    /// The class helps to merge many source into one and fetch it like a single source.
    class MultipleStreamSource: HistoryStreamSource {
        /// The list of sources
        private let sources: [HistoryStreamSource]

        init(sources: [HistoryStreamSource]) {
            self.sources = sources
            reset()
        }

        func first() async throws -> HistoryStreamSource.Result? {
            try await Observable
                .from(sources)
                .flatMap { source -> Observable<HistoryStreamSource.Result?> in
                    Observable.async { () -> HistoryStreamSource.Result? in try await source.first() }
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

        func next(configuration: FetchingConfiguration) -> AsyncThrowingStream<HistoryStreamSource.Result, Error> {
            AsyncThrowingStream<HistoryStreamSource.Result, Error> { stream in
                Task {
                    do {
                        for source in sources {
                            for try await transaction in source.next(configuration: configuration) {
                                stream.yield(transaction)
                            }
                        }
                        stream.finish(throwing: nil)
                    } catch {
                        stream.finish(throwing: error)
                    }
                }
            }
        }

        func reset() {
            for source in sources { source.reset() }
        }
    }
}
