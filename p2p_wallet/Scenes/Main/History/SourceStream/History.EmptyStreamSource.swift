//
// Created by Giang Long Tran on 19.04.2022.
//

import Foundation

extension History {
    class EmptyStreamSource: HistoryStreamSource {
        func next(configuration _: FetchingConfiguration) -> AsyncThrowingStream<SolanaSDK.SignatureInfo, Error> {
            AsyncThrowingStream<SolanaSDK.SignatureInfo, Error> { stream in stream.finish() }
        }

        func first() async throws -> SolanaSDK.SignatureInfo? { nil }

        func reset() {}
    }
}
