import Foundation
import Combine

/// Reusable ViewModel to manage a List of some Kind of item
@MainActor
class ListViewModel<
    Repository: AnyListRepository,
    MappingStrategy: ListMappingStrategy
>: ItemViewModel<Repository> where MappingStrategy.Sequence == Repository.ItemType {
    // MARK: - Properties
    
    let mappingStrategy: MappingStrategy
    
    // MARK: - Initializer
    
    /// ItemViewModel's initializer
    /// - Parameters:
    ///   - initialData: initial data for begining state of the Repository
    ///   - repository: repository to handle data fetching
    ///   - mappingStrategy: ListMappingStrategy
    init(
        initialData: ItemType?,
        repository: Repository,
        mappingStrategy: MappingStrategy? = nil
    ) {
        self.mappingStrategy = mappingStrategy ?? AppendUniqueItemListMappingStrategy<Repository.ListItemType>() as! MappingStrategy
        super.init(
            initialData: initialData,
            repository: repository
        )
    }

    // MARK: - Actions

    /// Erase data and reset repository to its initial state
    override func flush() {
        repository.paginationStrategy?.resetPagination()
        super.flush()
    }

    /// Refresh data
    override func refresh() {
        // if pagination enabled, erase and reload all data
        if let paginationStrategy = repository.paginationStrategy {
            paginationStrategy.resetPagination()
            super.reload()
        }

        // if pagination is not enabled, just refresh data without erasing current data
        else {
            super.refresh()
        }
    }

    /// Fetch next records if pagination is enabled
    func fetchNext() {
        // assert pagination is enabled
        guard repository.paginationStrategy != nil else {
            return
        }

        // call request
        super.request()
    }
    
    /// Handle new data that just received
    /// - Parameter newData: the new data received
    override func handleNewData(_ newData: ItemType?) {
        let data = mappingStrategy.map(oldData: data, newData: newData)
        super.handleNewData(data)
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

//    /// Update multiple records with a closure
//    /// - Parameter closure: updating closure
//    func batchUpdate(closure: ([ItemType]) -> [ItemType]) {
//        let newData = closure(data)
//        overrideData(by: newData)
//    }
//
//    /// Update item that matchs predicate
//    /// - Parameters:
//    ///   - predicate: predicate to find item
//    ///   - transform: transform item before udpate
//    /// - Returns: true if updated, false if not
//    @discardableResult
//    func updateItem(where predicate: (ItemType) -> Bool, transform: (ItemType) -> ItemType?) -> Bool {
//        // modify items
//        var itemsChanged = false
//        if let index = data.firstIndex(where: predicate),
//           let item = transform(data[index]),
//           item != data[index]
//        {
//            itemsChanged = true
//            var data = self.data
//            data[index] = item
//            overrideData(by: data)
//        }
//
//        return itemsChanged
//    }
//
//    /// Insert item into list or update if needed
//    /// - Parameters:
//    ///   - item: item to be inserted
//    ///   - predicate: predicate to find item
//    ///   - shouldUpdate: should update instead
//    /// - Returns: true if inserted, false if not
//    @discardableResult
//    func insert(_ item: ItemType, where predicate: ((ItemType) -> Bool)? = nil, shouldUpdate: Bool = false) -> Bool
//    {
//        var items = data
//
//        // update mode
//        if let predicate = predicate {
//            if let index = items.firstIndex(where: predicate), shouldUpdate {
//                items[index] = item
//                overrideData(by: items)
//                return true
//            }
//        }
//
//        // insert mode
//        else {
//            items.append(item)
//            overrideData(by: items)
//            return true
//        }
//
//        return false
//    }
//
//    /// Remove item that matches a predicate from list
//    /// - Parameter predicate: predicate to find item
//    /// - Returns: removed item
//    @discardableResult
//    func removeItem(where predicate: (ItemType) -> Bool) -> ItemType? {
//        var result: ItemType?
//        var data = self.data
//        if let index = data.firstIndex(where: predicate) {
//            result = data.remove(at: index)
//        }
//        if result != nil {
//            overrideData(by: data)
//        }
//        return nil
//    }
}
