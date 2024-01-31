import Foundation

/// PaginationStrategy using limit and offset
@MainActor
public class LimitOffsetPaginationStrategy: PaginationStrategy {
    // MARK: - Properties

    private let limit: Int
    private(set) var offset: Int = 0
    public private(set) var isLastPageLoaded: Bool = false

    // MARK: - Initializer

    public nonisolated init(limit: Int) {
        self.limit = limit
    }

    public func checkIfLastPageLoaded<ItemType>(lastSnapshot: [ItemType]?) {
        guard let lastSnapshot else {
            isLastPageLoaded = true
            return
        }
        isLastPageLoaded = lastSnapshot.count < limit
    }

    public func resetPagination() {
        offset = 0
        isLastPageLoaded = false
    }

    public func moveToNextPage() {
        offset += limit
    }
}
