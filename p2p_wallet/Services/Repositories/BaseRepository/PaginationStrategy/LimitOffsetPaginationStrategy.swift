import Foundation

/// PaginationStrategy using limit and offset
class LimitOffsetPaginationStrategy: PaginationStrategy {
    
    // MARK: - Properties

    let limit: Int
    @MainActor var offset: Int = 0
    @MainActor var isLastPageLoaded: Bool = false
    
    // MARK: - Initializer

    init(limit: Int) {
        self.limit = limit
    }
    
    @MainActor func checkIfLastPageLoaded<ItemType: ListItem>(lastSnapshot: [ItemType]?) {
        guard let lastSnapshot else {
            isLastPageLoaded = true
            return
        }
        isLastPageLoaded = lastSnapshot.count < limit
    }
    
    @MainActor func resetPagination() {
        offset = 0
    }
    
    @MainActor func moveToNextPage() {
        offset += limit
    }
}
