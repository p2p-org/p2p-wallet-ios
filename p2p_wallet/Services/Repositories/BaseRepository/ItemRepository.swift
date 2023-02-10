import Foundation
import Combine

@MainActor
class ItemRepository<T: Hashable>: ObservableObject {
    // MARK: - Properties

    let initialData: T
    
    var task: Task<Void, Error>?
    
    @Published var data: T
    @Published var state: LoadingState = .initializing
    @Published var error: Error?
    
    // MARK: - Initializer

    init(initialData: T) {
        self.initialData = initialData
        data = initialData
        bind()
    }
    
    func bind() {}
    
    // MARK: - Actions

    func flush() {
        data = initialData
        state = .initializing
        error = nil
    }
    
    func reload() {
        flush()
        request(reload: true)
    }
    
    // MARK: - Asynchronous request handler

    func createRequest() async throws -> T {
        fatalError("Must override")
    }
    
    func shouldRequest() -> Bool {
        state == .loading
    }
    
    func request(reload: Bool = false) {
        // cancel previous request
        task?.cancel()
        
        // mark as loading
        state = .loading
        error = nil
        
        // assign and execute task
        task = Task {
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
    
    func refresh() {
        request(reload: false)
    }
    
    func handleNewData(_ newData: T) {
        data = newData
        error = nil
        state = .loaded
    }
    
    func handleError(_ error: Error) {
        self.error = error
        state = .error
    }
    
    var dataDidChange: AnyPublisher<Void, Never> {
        $data.map {_ in ()}.eraseToAnyPublisher()
    }
}
