import Combine
import Foundation

/// Reusable ViewModel to manage a List of some Kind of item
open class ListRepository<P: ListProvider>: ObservableObject {
    // MARK: - Associated types

    /// Type of the item
    public typealias ItemType = P.ItemType

    // MARK: - Public properties

    /// Repository that is responsible for fetching data
    public let provider: P

    /// Current running task
    public let taskStorage = TaskStorage<[ItemType]>()

    /// The current data
    @Published @MainActor public var data: [ItemType] = []

    /// The current loading state of the data
    @Published @MainActor public var isLoading = false

    /// Optional error if occurred
    @Published @MainActor public var error: Error?

    // MARK: - Initializer

    /// ItemViewModel's initializer
    /// - Parameters:
    ///   - initialData: initial data for begining state of the Repository
    ///   - repository: repository to handle data fetching
    public init(
        initialData: [ItemType] = [],
        provider: P
    ) {
        self.provider = provider

        // feed data with initial data
        if !initialData.isEmpty {
            Task {
                await handleNewData(initialData)
            }
        }
    }

    // MARK: - Actions

    /// Erase data and reset repository to its initial state
    @MainActor
    open func flush() {
        data = []
        isLoading = false
        error = nil
    }

    /// Erase and reload all data
    open func reload() async {
        await flush()
        await request()
    }

    /// Refresh data without erasing current data
    open func refresh() async {
        await request()
    }

    /// Request data from outside to get new data
    /// - Returns: New data
    @discardableResult
    open func request() async -> Result<[ItemType], Error> {
        // prevent unwanted request
        guard provider.shouldFetch() else {
            return .failure(CancellationError())
        }

        // cancel previous request
        await taskStorage.cancelCurrentTask()

        // mark as loading
        await MainActor.run {
            isLoading = true
            error = nil
        }

        // assign and execute loadingTask
        await taskStorage.save(
            Task { [unowned self] in
                try await provider.fetch()
            }
        )

        // await value
        do {
            let newData = try await taskStorage.loadingTask!.value
            await handleNewData(newData)
            return .success(newData)
        } catch {
            // ignore cancellation error
            if !(error is CancellationError) {
                await handleError(error)
            }
            return .failure(error)
        }
    }

    /// Handle new data that just received
    /// - Parameter newData: the new data received
    @MainActor open func handleNewData(_ newData: [ItemType]) {
        data = newData
        error = nil
        isLoading = false
    }

    /// Handle error when received
    /// - Parameter err: the error received
    @MainActor open func handleError(_ err: Error) {
        error = err
        isLoading = false
    }

    // MARK: - Getter

    /// List loading state
    @MainActor
    open var state: ListLoadingState {
        // Empty state
        if data.isEmpty {
            let status: ListLoadingState.Status

            // empty loading
            if isLoading {
                status = .loading
            }

            // empty error
            else if let error {
                status = .error(error)
            }

            // empty
            else {
                status = .loaded
            }
            return .empty(status)
        }

        // Non-empty state
        else {
            return .nonEmpty(loadMoreStatus: .reachedEndOfList)
        }
    }

//    /// Override data
//    func overrideData(by newData: [ItemType]) {
//        guard state == .loaded else { return }
//        handleNewData(newData)
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
