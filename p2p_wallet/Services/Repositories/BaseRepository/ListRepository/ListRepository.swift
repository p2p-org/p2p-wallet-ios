import Combine
import Foundation

/// Repository to manage a List of some Kind of item
@MainActor
class ListRepository<ItemType: Hashable & Identifiable>: ItemRepository<[ItemType]> {
    // MARK: - Properties
    
    /// Strategy that indicates how pagination works, nil if pagination is disabled
    let paginationStrategy: PaginationStrategy?
    
    // MARK: - Initializer

    /// ListRepository's initializer
    /// - Parameters:
    ///   - initialData: initial data for begining state of the Repository
    ///   - paginationStrategy: Strategy that indicates how pagination works, nil if pagination is disabled
    init(
        initialData: [ItemType] = [],
        paginationStrategy: PaginationStrategy?
    ) {
        self.paginationStrategy = paginationStrategy
        super.init(initialData: initialData)
    }
    
    // MARK: - Actions

    /// Erase data and reset repository to its initial state
    override func reset(autoFetch: Bool = true) {
        paginationStrategy?.resetPagination()
        super.reset(autoFetch: autoFetch)
    }
    
    /// Indicate if repository can fetch more data
    /// - Returns: should fetch new data
    private func fetchable() -> Bool {
        guard let paginationStrategy else {
            return false
        }
        
        return !paginationStrategy.isLastPageLoaded
    }
    
    /// Fetch next records if pagination is enabled
    func fetchNext() {
        // assert pagination is enabled
        guard fetchable() == true else { return }
        
        // call request
        super.fetch()
    }
    
    /// Handle new data that just received
    /// - Parameter newData: the new data received
    override func handleData(_ newItems: [ItemType]) {
        var newData = data
        
        // for pagination
        if let paginationStrategy {
            // append data that is currently not existed in current data array
            newData += newItems.filter { !data.contains($0) }
            
            // resign state
            paginationStrategy.moveToNextPage()
            paginationStrategy.checkIfLastPageLoaded(lastSnapshot: newItems)
        }
        
        // without pagination
        else {
            // replace the current data
            newData = newItems
        }
        
        super.handleData(newData)
    }
    
    /// Handle error when received
    /// - Parameter err: the error received
    override func handleError(_ err: Error) {
        super.handleError(err)
    }
    
    /// Force override current data with newData
    /// - Parameter newData: newData to be overriden
    func overrideData(by newData: [ItemType]) {
        super.handleData(newData)
    }
}
