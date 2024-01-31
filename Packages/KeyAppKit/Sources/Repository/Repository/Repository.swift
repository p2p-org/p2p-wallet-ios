import Combine
import Foundation

/// Reusable ViewModel to manage item
open class Repository<P: Provider>: ObservableObject {
    // MARK: - Associated types

    /// Type of the item
    public typealias ItemType = P.ItemType

    // MARK: - Public properties

    /// Repository that is responsible for fetching data
    public let provider: P

    /// Current running task
    private let taskStorage = TaskStorage<ItemType?>()

    /// The current data
    @Published @MainActor public private(set) var data: ItemType?

    /// The current loading state of the data
    @Published @MainActor public private(set) var isLoading = false

    /// Optional error if occurred
    @Published @MainActor public private(set) var error: Error?

    // MARK: - Initializer

    /// ItemViewModel's initializer
    /// - Parameters:
    ///   - initialData: initial data for begining state of the Repository
    ///   - repository: repository to handle data fetching
    public init(
        initialData: ItemType?,
        provider: P
    ) {
        self.provider = provider

        // feed data with initial data
        Task {
            await handleNewData(initialData)
        }
    }

    // MARK: - Actions

    /// Erase data and reset repository to its initial state
    @MainActor
    open func flush() {
        data = nil
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
    @discardableResult
    open func request() async -> Result<ItemType?, Error> {
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
            let newData = try await taskStorage.loadingTask?.value
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
    @MainActor open func handleNewData(_ newData: ItemType?) {
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

    /// Override data
    @MainActor open func overrideData(by newData: ItemType?) {
        handleNewData(newData)
    }

    // MARK: - Getters

    /// List loading state
    @MainActor open var state: LoadingState {
        if data == nil, isLoading == false, error == nil {
            return .initialized
        }

        if isLoading {
            return .loading
        }

        if error != nil {
            return .error
        }

        return .loaded
    }
}
