import Foundation

/// Repository that is only responsible for fetching item
protocol AnyRepository {
    /// ItemType to be fetched
    associatedtype ItemType: Hashable
    /// Indicate if should fetching item
    func shouldFetch() -> Bool
    /// Fetch item from outside
    func fetch() async throws -> ItemType?
    /// FIXME: - Join
    func map(oldData: ItemType?, newData: ItemType?) -> ItemType?
}

protocol AnyListRepository: AnyRepository {
    /// ListItemType to be fetched
    associatedtype ListItemType: Hashable
    /// Pagination strategy
    var paginationStrategy: PaginationStrategy? { get }
    /// Fetch list of item from outside
    func fetch() async throws -> [ListItemType]?
    
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

class ListRepository<ListItemType: Hashable>: AnyListRepository {
    // MARK: - Properties

    /// Strategy that indicates how pagination works, nil if pagination is disabled
    let paginationStrategy: PaginationStrategy?

    // MARK: - Initializer
    init(paginationStrategy: PaginationStrategy? = nil) {
        self.paginationStrategy = paginationStrategy
    }

    func shouldFetch() -> Bool {
        true
    }

    func fetch() async throws -> [ListItemType]? {
        fatalError()
    }
    
    func map(oldData: [ListItemType]?, newData: [ListItemType]?) -> [ListItemType]? {
        guard var data = oldData else { return nil }

        // for pagination
        if let paginationStrategy = paginationStrategy {
            // append data that is currently not existed in current data array
            if let newData {
                data += newData.filter {!data.contains($0)}
            }

            // resign state
            paginationStrategy.moveToNextPage()
            paginationStrategy.checkIfLastPageLoaded(lastSnapshot: newData)
        }

        // without pagination
        else {
            // replace the current data
            if let newData {
                data = newData
            }
        }

        return data
    }
}

//extension AsyncSequence: Repository {
//    func fetch() async throws {
//        let iterator = makeAsyncIterator()
//        return iterator.next()
//    }
//}
