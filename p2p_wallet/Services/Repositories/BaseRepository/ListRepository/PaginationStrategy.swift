import Foundation

/// Strategy of to define how pagination works in ListRepository
protocol PaginationStrategy {
    /// Boolean value to indicate that last page was loaded or not
    var isLastPageLoaded: Bool { get }
    /// Reset pagination
    func resetPagination()
}
