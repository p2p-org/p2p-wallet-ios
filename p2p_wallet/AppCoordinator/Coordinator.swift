//
//  Coordinator.swift
//  p2p_wallet
//
//  Created by Chung Tran on 21/07/2022.
//

import Combine
import Foundation

enum CoordinatorError: Error {
    case isAlreadyStarted
}

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

    @discardableResult
    open func coordinate<T>(to coordinator: Coordinator<T>) -> AnyPublisher<T, Error> {
        store(coordinator: coordinator)
        return coordinator.start()
            .handleEvents(receiveCompletion: { [weak self] completion in
                switch completion {
                case let .failure(error):
                    self?.release(coordinator: coordinator)
                // TODO: - Handle error
                case .finished:
                    self?.release(coordinator: coordinator)
                }
            })
            .eraseToAnyPublisher()
    }

    open func start() -> AnyPublisher<ResultType, Error> {
        fatalError("start() method must be implemented")
    }
}
