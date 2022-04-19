//
// Created by Giang Long Tran on 18.04.2022.
//

import Foundation

extension History {
    /// The class helps to merge many source into one and fetch it like a single source.
    class MultipleStreamSource: HistoryStreamSource {
        /// The list of sources
        private let sources: [HistoryStreamSource]

        init(sources: [HistoryStreamSource]) {
            self.sources = sources
            reset()
        }

        func first() async throws -> SolanaSDK.ParsedTransaction? {
            var mostFirst: SolanaSDK.ParsedTransaction?
            for source in sources {
                let trx = try await source.first()

                guard let t1 = trx?.blockTime else { continue }
                guard let t2 = mostFirst?.blockTime else {
                    mostFirst = trx
                    continue
                }

                if t1 > t2 {
                    mostFirst = trx
                }
            }
            return mostFirst
        }

        func next(configuration: FetchingConfiguration) -> AsyncThrowingStream<SolanaSDK.ParsedTransaction, Error> {
            AsyncThrowingStream<SolanaSDK.ParsedTransaction, Error> { stream in
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
