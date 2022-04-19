//
// Created by Giang Long Tran on 19.04.2022.
//

import Foundation

extension History {
    class EmptyStreamSource: HistoryStreamSource {
        func next(configuration _: FetchingConfiguration) -> AsyncThrowingStream<SolanaSDK.ParsedTransaction, Error> {
            AsyncThrowingStream<SolanaSDK.ParsedTransaction, Error> { stream in stream.finish() }
        }

        func first() async throws -> SolanaSDK.ParsedTransaction? { nil }

        func reset() {}
    }
}
