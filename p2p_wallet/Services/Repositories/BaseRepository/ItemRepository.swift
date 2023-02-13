import Combine
import Foundation

/// Repository to manage some kind of Item
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
    public init(initialData: ItemType) {
        self.initialData = initialData
        data = initialData
    }
    
    // MARK: - Asynchronous request handler
    
    /// The request to retrieve data into repository
    /// - Returns: item
    internal func request() async throws -> ItemType {
        fatalError("Must override")
    }
    
    // MARK: - Actions

    /// Erase data and reset repository to its initial state
    public func reset(autoFetch: Bool = true) {
        data = initialData
        state = .initializing
        error = nil
        
        if autoFetch {
            fetch()
        }
    }
    
    /// Request data from outside to get new data
    public func fetch() {
        // Ensure only one task at current moment
        guard loadingTask == nil else { return }
        
        // cancel previous request
        loadingTask?.cancel()
        
        // mark as loading
        state = .fetching
        error = nil
        
        // assign and execute loadingTask
        loadingTask = Task {
            do {
                defer { loadingTask = nil }
                
                let newData = try await request()
                await handleData(newData)
            } catch {
                if error is CancellationError { return }
                await handleError(error)
            }
        }
    }
    
    /// Handle new data that just received
    /// - Parameter newData: the new data received
    @MainActor
    func handleData(_ newData: ItemType) {
        data = newData
        error = nil
        state = .fetching
    }
    
    /// Handle error when received
    /// - Parameter err: the error received
    @MainActor
    func handleError(_ err: Error) {
        error = err
        state = .error
    }
}
