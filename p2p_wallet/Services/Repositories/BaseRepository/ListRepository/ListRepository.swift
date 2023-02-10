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
        guard paginationStrategy != nil else {
            return
        }
        super.request()
    }
    
    override func handleNewData(_ newItems: [ItemType]) {
        let newData = self.join(newItems)
        
        // resign state
        if !isPaginationEnabled || newItems.count < limit {
            isLastPageLoaded = true
        }
        
        // map
        let mappedData = map(newData: newData)
        super.handleNewData(mappedData)
        
        // get next offset
        offset += limit
    }
    
    func join(_ newItems: [ItemType]) -> [ItemType] {
        if !isPaginationEnabled {
            return newItems
        }
        return data + newItems.filter {!data.contains($0)}
    }
    
    func overrideData(by newData: [ItemType]) {
        let newData = map(newData: newData)
        if newData != data {
            super.handleNewData(newData)
        }
    }
    
    func map(newData: [ItemType]) -> [ItemType] {
        var newData = newData
        if let customFilter = customFilter {
            newData = newData.filter {customFilter($0)}
        }
        if let sorter = self.customSorter {
            newData = newData.sorted(by: sorter)
        }
        return newData
    }
    
    func setState(_ state: LoadingState, withData data: [AnyHashable]? = nil) {
        self.state = state
        if let data = data as? [ItemType] {
            overrideData(by: data)
        }
    }
    
    func refreshUI() {
        overrideData(by: data)
    }
    
    func updateFirstPage(onSuccessFilterNewData: (([ItemType]) -> [ItemType])? = nil) {
        let originalOffset = offset
        offset = 0
        
        task?.cancel()
        
        task = Task {
            let onSuccess = onSuccessFilterNewData ?? {[weak self] newData in
                newData.filter {!(self?.data.contains($0) == true)}
            }
            var data = self.data
            let newData = try await self.createRequest()
            data = onSuccess(newData) + data
            self.overrideData(by: data)
        }
        
        offset = originalOffset
    }
    
    func getCurrentPage() -> Int? {
        guard isPaginationEnabled, limit != 0 else {return nil}
        return offset / limit
    }
    
    // MARK: - Helper
    func batchUpdate(closure: ([ItemType]) -> [ItemType]) {
        let newData = closure(data)
        overrideData(by: newData)
    }
    
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
    
    func convertDataToAnyHashable() -> [AnyHashable] {
        data as [AnyHashable]
    }
}
