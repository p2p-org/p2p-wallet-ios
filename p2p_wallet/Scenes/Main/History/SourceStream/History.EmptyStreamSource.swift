//
// Created by Giang Long Tran on 19.04.2022.
//

import Foundation

extension History {
    class EmptyStreamSource: HistoryStreamSource {
        func next(configuration _: FetchingConfiguration) -> AsyncThrowingStream<HistoryStreamSource.Result, Error> {
            AsyncThrowingStream<HistoryStreamSource.Result, Error> { stream in stream.finish() }
        }

        func first() async throws -> HistoryStreamSource.Result? { nil }

        func reset() {}
    }
}
