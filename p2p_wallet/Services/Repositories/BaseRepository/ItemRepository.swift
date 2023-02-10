import Foundation
import Combine

/// Repository to manage some kind of Item
@MainActor
class ItemRepository<ItemType: Hashable>: ObservableObject {
    // MARK: - Private properties
    
    /// Initial data for initializing state
    private let initialData: ItemType
    
    // MARK: - Public properties
    
    /// Current running task
    var loadingTask: Task<Void, Error>?
    
    /// The current data
    @Published var data: ItemType

    /// The current loading state of the data
    @Published var state: LoadingState = .initializing

    /// Optional error if occurred
    @Published var error: Error?
    
    // MARK: - Initializer
    
    /// ItemRepository's initializer
    /// - Parameter initialData: initial data for begining state of the Repository
    init(initialData: ItemType) {
        self.initialData = initialData
        data = initialData
    }
    
    // MARK: - Asynchronous request handler
    
    /// The request to retrieve data into repository
    /// - Returns: item
    func createRequest() async throws -> ItemType {
        fatalError("Must override")
    }
    
    // MARK: - Actions

    /// Erase data and reset repository to its initial state
    func flush() {
        data = initialData
        state = .initializing
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
    
    /// Indicate if should fetch new data to prevent unwanted request
    /// - Returns: should fetch new data
    func shouldRequest() -> Bool {
        true
    }
    
    /// Request data from outside to get new data
    func request() {
        // prevent unwanted request
        guard shouldRequest() else {
            return
        }
        
        // cancel previous request
        loadingTask?.cancel()
        
        // mark as loading
        state = .loading
        error = nil
        
        // assign and execute loadingTask
        loadingTask = Task {
            do {
                let newData = try await createRequest()
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
    func handleNewData(_ newData: ItemType) {
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
}
