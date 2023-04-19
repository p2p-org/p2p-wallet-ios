// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation

public actor SendInputStateMachine: StateMachine {
    // Associated types
    public typealias Action = SendInputAction
    public typealias Services = SendInputServices
    public typealias State = SendInputState

    // Container
    private nonisolated let stateSubject: CurrentValueSubject<SendInputState, Never>

    // Variables
    public nonisolated var statePublisher: AnyPublisher<SendInputState, Never> { stateSubject.eraseToAnyPublisher() }
    public nonisolated var currentState: SendInputState { stateSubject.value }

    // Constants
    public nonisolated let services: SendInputServices

    public init(initialState: SendInputState, services: SendInputServices) {
        stateSubject = .init(initialState)
        self.services = services
    }

    public func accept(action: SendInputAction) async -> SendInputState {
        let newState = await SendInputBusinessLogic.sendInputBusinessLogic(state: currentState, action: action, services: services)
        stateSubject.send(newState)
        return newState
    }
}
