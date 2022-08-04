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
    public var subscriptions = Set<AnyCancellable>()

    @discardableResult
    open func coordinate<T>(to coordinator: Coordinator<T>) -> AnyPublisher<T, Never> {
        coordinator.start()
    }

    open func start() -> AnyPublisher<ResultType, Never> {
        fatalError("start() method must be implemented")
    }
}
