import Combine
import Foundation

@MainActor
open class Coordinator<ResultType>: NSObject {
    // MARK: - Properties

    public var subscriptions = [AnyCancellable]()
    private let identifier = UUID()
    private var childCoordinators = [UUID: Any]()

    // MARK: - Methods

    private func store<T>(coordinator: Coordinator<T>) {
        childCoordinators[coordinator.identifier] = coordinator
    }

    private func release<T>(coordinator: Coordinator<T>) {
        childCoordinators[coordinator.identifier] = nil
    }

    open func coordinate<T>(to coordinator: Coordinator<T>) -> AnyPublisher<T, Never> {
        store(coordinator: coordinator)
        return coordinator.start()
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.release(coordinator: coordinator)
            })
            .eraseToAnyPublisher()
    }

    open func start() -> AnyPublisher<ResultType, Never> {
        fatalError("start() method must be implemented")
    }
}
