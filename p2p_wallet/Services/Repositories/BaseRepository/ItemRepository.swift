import Combine
import Foundation

/// Repository to manage some kind of Item
class ItemRepository<ItemType: Hashable>: ObservableObject {
    typealias RepositoryTask = Task<Void, Error>
    
    // MARK: - Private properties
    
    /// Initial data for initializing state
    private let initialData: ItemType
    
    // MARK: - Public properties
    
    /// Current running task
    internal var currentTask: RepositoryTask?
    
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
    @discardableResult public func reset(autoFetch: Bool = true) -> RepositoryTask? {
        currentTask?.cancel()
        currentTask = nil
        
        data = initialData
        state = .initializing
        error = nil
        
        if autoFetch {
            return fetch()
        }
        
        return nil
    }
    
    internal func fetchable() -> Bool {
        return true
    }
    
    /// Request data from outside to get new data
    @discardableResult public func fetch() -> RepositoryTask? {
        // Ensure only one task at current moment
        guard state != .fetching else { return currentTask }
        guard fetchable() else { return nil }
        
        // mark as loading
        state = .fetching
        error = nil
        
        // assign and execute loadingTask
        currentTask = Task {
            do {
                defer { currentTask = nil }

                let newData: ItemType = try await request()
                await handleData(newData)
            } catch {
                if error is CancellationError { return }
                await handleError(error)

                throw error
            }
        }
        
        return currentTask
    }
    
    /// Handle new data that just received
    /// - Parameter newData: the new data received
    @MainActor
    func handleData(_ newData: ItemType) {
        data = newData
        error = nil
        state = .ready
    }
    
    /// Handle error when received
    /// - Parameter err: the error received
    @MainActor
    func handleError(_ err: Error) {
        error = err
        state = .error
    }
}
