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
    
    @MainActor func checkIfLastPageLoaded<ItemType: Hashable>(lastSnapshot: [ItemType]) {
        isLastPageLoaded = lastSnapshot.count < limit
    }
    
    @MainActor func resetPagination() {
        offset = 0
    }
    
    @MainActor func moveToNextPage() {
        offset += limit
    }
}