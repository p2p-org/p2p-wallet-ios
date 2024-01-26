import Foundation

public actor TaskStorage<ItemType> {
    public var loadingTask: Task<ItemType, Error>?

    public func save(_ task: Task<ItemType, Error>) {
        loadingTask = task
    }

    public func cancelCurrentTask() {
        loadingTask?.cancel()
        loadingTask = nil
    }
}
