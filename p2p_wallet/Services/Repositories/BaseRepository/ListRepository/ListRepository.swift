import Foundation
import Combine

/// Repository to manage a List of some Kind of item
@MainActor
class ListRepository<ItemType: Hashable>: ItemRepository<[ItemType]> {

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
    override func flush() {
        paginationStrategy?.resetPagination()
        super.flush()
    }
    
    /// Erase and reload all data
    override func reload() {
        super.reload()
    }
    
    /// Refresh data
    override func refresh() {
        // if pagination enabled, erase and reload all data
        if let paginationStrategy {
            paginationStrategy.resetPagination()
            super.reload()
        }
        
        // if pagination is not enabled, just refresh data without erasing current data
        else {
            super.refresh()
        }
    }
    
    /// Indicate if should fetch new data to prevent unwanted request
    /// - Returns: should fetch new data
    override func shouldRequest() -> Bool {
        var shouldRequest = super.shouldRequest()
        
        // check if isLastPageLoaded
        if let paginationStrategy {
            shouldRequest = shouldRequest && !paginationStrategy.isLastPageLoaded
        }
        
        return shouldRequest
    }
    
    /// Fetch next records if pagination is enabled
    func fetchNext() {
        // assert pagination is enabled
        guard let paginationStrategy else {
            return
        }
        
        // call request
        super.request()
    }
    
    /// Handle new data that just received
    /// - Parameter newData: the new data received
    override func handleNewData(_ newItems: [ItemType]) {
        var newData = data
        
        // for pagination
        if let paginationStrategy {
            // append data that is currently not existed in current data array
            newData += newItems.filter {!data.contains($0)}
            
            // resign state
            paginationStrategy.moveToNextPage()
            paginationStrategy.checkIfLastPageLoaded(lastSnapshot: newData)
        }
        
        // without pagination
        else {
            // replace the current data
            newData = newItems
        }
        
        super.handleNewData(newData)
    }
    
    /// Handle error when received
    /// - Parameter err: the error received
    override func handleError(_ err: Error) {
        super.handleError(err)
    }
    
    /// Force override current data with newData
    /// - Parameter newData: newData to be overriden
    func overrideData(by newData: [ItemType]) {
        super.handleNewData(newData)
    }
    
//    func updateFirstPage(onSuccessFilterNewData: (([ItemType]) -> [ItemType])? = nil) {
//        let originalOffset = offset
//        offset = 0
//
//        task?.cancel()
//
//        task = Task {
//            let onSuccess = onSuccessFilterNewData ?? {[weak self] newData in
//                newData.filter {!(self?.data.contains($0) == true)}
//            }
//            var data = self.data
//            let newData = try await self.createRequest()
//            data = onSuccess(newData) + data
//            self.overrideData(by: data)
//        }
//
//        offset = originalOffset
//    }
    
    /// Update multiple records with a closure
    /// - Parameter closure: updating closure
    func batchUpdate(closure: ([ItemType]) -> [ItemType]) {
        let newData = closure(data)
        overrideData(by: newData)
    }
    
    /// Update item that matchs predicate
    /// - Parameters:
    ///   - predicate: predicate to find item
    ///   - transform: transform item before udpate
    /// - Returns: true if updated, false if not
    @discardableResult
    func updateItem(where predicate: (ItemType) -> Bool, transform: (ItemType) -> ItemType?) -> Bool {
        // modify items
        var itemsChanged = false
        if let index = data.firstIndex(where: predicate),
           let item = transform(data[index]),
           item != data[index]
        {
            itemsChanged = true
            var data = self.data
            data[index] = item
            overrideData(by: data)
        }
        
        return itemsChanged
    }
    
    /// Insert item into list or update if needed
    /// - Parameters:
    ///   - item: item to be inserted
    ///   - predicate: predicate to find item
    ///   - shouldUpdate: should update instead
    /// - Returns: true if inserted, false if not
    @discardableResult
    func insert(_ item: ItemType, where predicate: ((ItemType) -> Bool)? = nil, shouldUpdate: Bool = false) -> Bool
    {
        var items = data
        
        // update mode
        if let predicate = predicate {
            if let index = items.firstIndex(where: predicate), shouldUpdate {
                items[index] = item
                overrideData(by: items)
                return true
            }
        }
        
        // insert mode
        else {
            items.append(item)
            overrideData(by: items)
            return true
        }
        
        return false
    }
    
    /// Remove item that matches a predicate from list
    /// - Parameter predicate: predicate to find item
    /// - Returns: removed item
    @discardableResult
    func removeItem(where predicate: (ItemType) -> Bool) -> ItemType? {
        var result: ItemType?
        var data = self.data
        if let index = data.firstIndex(where: predicate) {
            result = data.remove(at: index)
        }
        if result != nil {
            overrideData(by: data)
        }
        return nil
    }
}
