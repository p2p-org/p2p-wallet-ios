//
// Created by Giang Long Tran on 19.04.2022.
//

import Foundation

extension History {
    class EmptyStreamSource: HistoryStreamSource {
        func next(configuration _: FetchingConfiguration) async throws -> HistoryStreamSource.Result? { nil }

        func currentItem() async throws -> HistoryStreamSource.Result? { nil }

        func reset() {}
    }
}
