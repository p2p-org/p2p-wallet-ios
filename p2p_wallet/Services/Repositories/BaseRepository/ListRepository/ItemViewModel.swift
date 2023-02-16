import Foundation
import Combine

/// Reusable ViewModel to manage item
@MainActor
class ItemViewModel<Repository: AnyRepository>: ObservableObject {
    // MARK: - Associated types
    
    /// Type of the item
    typealias ItemType = Repository.ItemType
    
    // MARK: - Private properties
    
    /// Initial data for initializing state
    private let initialData: ItemType?
    
    // MARK: - Public properties
    
    /// Repository that is responsible for fetching data
    let repository: Repository
    
    /// Current running task
    var loadingTask: Task<Void, Error>?
    
    /// The current data
    @Published var data: ItemType?

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
        initialData: ItemType?,
        repository: Repository
    ) {
        self.initialData = initialData
        self.repository = repository
        data = initialData
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
    func handleNewData(_ newData: ItemType?) {
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
