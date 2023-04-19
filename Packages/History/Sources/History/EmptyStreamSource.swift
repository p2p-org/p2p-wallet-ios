//
// Created by Giang Long Tran on 19.04.2022.
//

import Foundation

public class EmptyStreamSource: HistoryStreamSource {
    public init() {}
    
    public func next(configuration _: FetchingConfiguration) async throws -> HistoryStreamSource.Result? { nil }
    
    public func currentItem() async throws -> HistoryStreamSource.Result? { nil }
    
    public func reset() {}
}
