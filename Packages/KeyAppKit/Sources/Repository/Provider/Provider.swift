import Foundation

/// Repository that is only responsible for fetching item
public protocol Provider<ItemType> {
    /// ItemType to be fetched
    associatedtype ItemType
    /// Indicate if should fetching item
    func shouldFetch() -> Bool
    /// Fetch item from outside
    func fetch() async throws -> ItemType?
}

public extension Provider {
    func shouldFetch() -> Bool {
        true
    }
}

// class ListRepository<ItemType: Hashable & Identifiable>: AnyListRepository {
//    // MARK: - Properties
//
//    /// Strategy that indicates how pagination works, nil if pagination is disabled
//    let paginationStrategy: PaginationStrategy?
//
//    // MARK: - Initializer
//    init(paginationStrategy: PaginationStrategy? = nil) {
//        self.paginationStrategy = paginationStrategy
//    }
//
//    func shouldFetch() -> Bool {
//        var shouldRequest: Bool = true
//
//        // check if isLastPageLoaded
//        if let paginationStrategy {
//            shouldRequest = shouldRequest && !paginationStrategy.isLastPageLoaded
//        }
//
//        return shouldRequest
//    }
//
//    func fetch() async throws -> [ItemType] {
//        fatalError("Must override")
//    }
// }

// extension AsyncSequence: Repository {
//    func fetch() async throws {
//        let iterator = makeAsyncIterator()
//        return iterator.next()
//    }
// }
