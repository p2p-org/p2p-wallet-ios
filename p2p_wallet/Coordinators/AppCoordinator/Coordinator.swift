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
    private let identifier = UUID()

    private var childCoordinators: [UUID: Any] = [:]

    public var subscriptions = Set<AnyCancellable>()

    @discardableResult
    open func coordinate<T>(to coordinator: Coordinator<T>) -> AnyPublisher<T, Never> {
        store(coordinator: coordinator)
        let subject = PassthroughSubject<T, Never>()

        coordinator.start()
            .sink(receiveValue: { [weak self, weak coordinator] value in
                subject.send(value)
                if let coordinator = coordinator {
                    self?.free(coordinator: coordinator)
                }
            })
            .store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    open func start() -> AnyPublisher<ResultType, Never> {
        fatalError("start() method must be implemented")
    }

    private func store<T>(coordinator: Coordinator<T>) {
        childCoordinators[coordinator.identifier] = coordinator
    }

    private func free<T>(coordinator: Coordinator<T>) {
        childCoordinators.removeValue(forKey: coordinator.identifier)
    }
}
