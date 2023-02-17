import Foundation
import Combine

/// Reusable ViewModel to manage a List of some Kind of item
@MainActor
class ListViewModel<Repository: AnyListRepository>: ObservableObject {
    
    // MARK: - Associated types
    
    /// Type of the item
    typealias ItemType = Repository.ItemType
    
    // MARK: - Private properties
    
    /// Initial data for initializing state
    private let initialData: [ItemType]
    
    // MARK: - Public properties
    
    /// Repository that is responsible for fetching data
    let repository: Repository
    
    /// Current running task
    var loadingTask: Task<Void, Error>?
    
    /// The current data
    @Published var data: [ItemType] = []

    /// The current loading state of the data
    @Published var state: LoadingState = .initialized

    /// Optional error if occurred
    @Published var error: Error?
    
    // MARK: - Initializer
    
    /// ItemViewModel's initializer
    /// - Parameters:
    ///   - initialData: initial data for begining state of the Repository
    ///   - repository: repository to handle data fetching
    init(
        initialData: [ItemType] = [],
        repository: Repository
    ) {
        self.initialData = initialData
        self.repository = repository
        
        flush()
    }

    // MARK: - Actions

    /// Erase data and reset repository to its initial state
    func flush() {
        data = initialData
        state = .initialized
        error = nil
    }
    
    /// Erase and reload all data
    func reload() {
        flush()
        request()
    }
    
    /// Refresh data without erasing current data
    func refresh() {
        request()
    }
    
    /// Request data from outside to get new data
    func request() {
        // prevent unwanted request
        guard repository.shouldFetch() else {
            return
        }
        
        // cancel previous request
        loadingTask?.cancel()
        
        // mark as loading
        state = .loading
        error = nil
        
        // assign and execute loadingTask
        loadingTask = Task { [unowned self] in
            do {
                let newData = try await repository.fetch()
                handleNewData(newData)
            } catch {
                if error is CancellationError {
                    return
                }
                handleError(error)
            }
        }
    }
    
    /// Handle new data that just received
    /// - Parameter newData: the new data received
    func handleNewData(_ newData: [ItemType]) {
        data = newData
        error = nil
        state = .loaded
    }
    
    /// Handle error when received
    /// - Parameter err: the error received
    func handleError(_ err: Error) {
        error = err
        state = .error
    }
    
    /// Override data
    func overrideData(by newData: [ItemType]) {
        handleNewData(newData)
    }

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
