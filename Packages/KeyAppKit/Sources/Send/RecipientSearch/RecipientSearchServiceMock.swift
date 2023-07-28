import Foundation
import SolanaSwift

public class RecipientSearchServiceMock: RecipientSearchService {
    let result: RecipientSearchResult

    public init(result: RecipientSearchResult) { self.result = result }

    public func search(input _: String, config _: RecipientSearchConfig,
                       preChosenToken _: TokenMetadata?) async -> RecipientSearchResult { result }
}
