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

protocol AnyListRepository: AnyRepository {
    /// Pagination strategy
    var paginationStrategy: PaginationStrategy? { get }
    /// Fetch list of item from outside
    func fetch() async throws -> [ItemType]?
    /// Reload
    func reload()
    
//    /// Indicate if should fetch new data to prevent unwanted request
//    /// - Returns: should fetch new data
//    func shouldFetch() -> Bool {
//        var shouldRequest = super.shouldRequest()
//
//        // check if isLastPageLoaded
//        if let paginationStrategy {
//            shouldRequest = shouldRequest && !paginationStrategy.isLastPageLoaded
//        }
//
//        return shouldRequest
//    }
}

//class ListRepository<ItemType: Hashable>: AnyRepository {
//    // MARK: - Properties
//
//    /// Strategy that indicates how pagination works, nil if pagination is disabled
//    let paginationStrategy: PaginationStrategy?
//
//    func shouldFetch() -> Bool {
//        true
//    }
//
//    func fetch() async throws -> [ItemType]? {
//        nil
//    }
//}

//extension AsyncSequence: Repository {
//    func fetch() async throws {
//        let iterator = makeAsyncIterator()
//        return iterator.next()
//    }
//}
