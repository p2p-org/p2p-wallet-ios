import Foundation
import Combine

class ListRepository<T: Hashable>: ItemRepository<[T]> {

    // MARK: - Properties

    var isPaginationEnabled: Bool
    var customFilter: ((T) -> Bool)?
    var customSorter: ((T, T) -> Bool)?
    var isEmpty: Bool {isLastPageLoaded && data.count == 0}
    
    // For pagination
    var limit: Int
    var offset: Int
    private var isLastPageLoaded = false
    
    // MARK: - Initializer
    init(
        initialData: [T] = [],
        isPaginationEnabled: Bool = false,
        limit: Int = 10,
        offset: Int = 0
    ) {
        self.isPaginationEnabled = isPaginationEnabled
        self.limit = limit
        self.offset = offset
        super.init(initialData: initialData)
    }
    
    // MARK: - Actions
    override func flush() {
        offset = 0
        isLastPageLoaded = false
        super.flush()
    }
    
    // MARK: - Asynchronous request handler
    override func shouldRequest() -> Bool {
        super.shouldRequest() && !isLastPageLoaded
    }
    
    func fetchNext() {
        super.request()
    }
    
    override func handleNewData(_ newItems: [T]) {
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
    
    func join(_ newItems: [T]) -> [T] {
        if !isPaginationEnabled {
            return newItems
        }
        return data + newItems.filter {!data.contains($0)}
    }
    
    func overrideData(by newData: [T]) {
        let newData = map(newData: newData)
        if newData != data {
            super.handleNewData(newData)
        }
    }
    
    func map(newData: [T]) -> [T] {
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
        if let data = data as? [T] {
            overrideData(by: data)
        }
    }
    
    func refreshUI() {
        overrideData(by: data)
    }
    
    func updateFirstPage(onSuccessFilterNewData: (([T]) -> [T])? = nil) {
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
    func batchUpdate(closure: ([T]) -> [T]) {
        let newData = closure(data)
        overrideData(by: newData)
    }
    
    @discardableResult
    func updateItem(where predicate: (T) -> Bool, transform: (T) -> T?) -> Bool {
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
    func insert(_ item: T, where predicate: ((T) -> Bool)? = nil, shouldUpdate: Bool = false) -> Bool
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
    func removeItem(where predicate: (T) -> Bool) -> T? {
        var result: T?
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
