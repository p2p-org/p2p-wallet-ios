import Foundation

public protocol PaginatedListProvider: ListProvider {
    associatedtype PS: PaginationStrategy
    /// Pagination strategy
    var paginationStrategy: PS { get }
}

public extension PaginatedListProvider {
    @MainActor func shouldFetch() -> Bool {
        !paginationStrategy.isLastPageLoaded
    }
}
