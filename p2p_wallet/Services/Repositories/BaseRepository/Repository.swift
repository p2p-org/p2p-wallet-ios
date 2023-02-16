import Foundation

/// Repository that is only responsible for fetching item
protocol AnyRepository {
    /// ItemType to be fetched
    associatedtype ItemType: Hashable
    /// Indicate if should fetching item
    func shouldFetch() -> Bool
    /// Fetch item from outside
    func fetch() async throws -> ItemType?
}

//extension AsyncSequence: Repository {
//    func fetch() async throws {
//        let iterator = makeAsyncIterator()
//        return iterator.next()
//    }
//}
