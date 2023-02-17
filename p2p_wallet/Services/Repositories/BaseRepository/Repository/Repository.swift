import Foundation

/// Repository that is only responsible for fetching item
protocol AnyRepository {
    /// ItemType to be fetched
    associatedtype ItemType
    /// Indicate if should fetching item
    func shouldFetch() -> Bool
    /// Fetch item from outside
    func fetch() async throws -> ItemType?
}

/// Repository that is only responsible for fetching list of items
protocol AnyListRepository {
    /// ListItemType to be fetched
    associatedtype ItemType: Hashable & Identifiable
    /// Indicate if should fetching item
    func shouldFetch() -> Bool
    /// Fetch list of item from outside
    func fetch() async throws -> [ItemType]
}

protocol AnyPaginatedListRepository: AnyListRepository {
    /// Pagination strategy
    var paginationStrategy: PaginationStrategy { get }
}

class ListRepository<ItemType: Hashable & Identifiable>: AnyListRepository {
    // MARK: - Properties

    /// Strategy that indicates how pagination works, nil if pagination is disabled
    let paginationStrategy: PaginationStrategy?

    // MARK: - Initializer
    init(paginationStrategy: PaginationStrategy? = nil) {
        self.paginationStrategy = paginationStrategy
    }

    func shouldFetch() -> Bool {
        var shouldRequest: Bool = true
        
        // check if isLastPageLoaded
        if let paginationStrategy {
            shouldRequest = shouldRequest && !paginationStrategy.isLastPageLoaded
        }

        return shouldRequest
    }

    func fetch() async throws -> [ItemType] {
        fatalError("Must override")
    }
}

//extension AsyncSequence: Repository {
//    func fetch() async throws {
//        let iterator = makeAsyncIterator()
//        return iterator.next()
//    }
//}
