import Foundation

/// PaginationStrategy using limit and offset
class LimitOffsetPaginationStrategy: PaginationStrategy {
    
    // MARK: - Properties

    let limit: Int
    var offset: Int = 0
    var isLastPage: Bool = false
    
    // MARK: - Initializer

    init(limit: Int) {
        self.limit = limit
    }
    
    func handle<ItemType: Hashable>(data: [ItemType]) {
        offset += data.count
        isLastPage = data.count < limit
    }
    
    func resetPagination() {
        offset = 0
    }
}
