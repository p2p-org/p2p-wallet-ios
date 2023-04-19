//
//  File.swift
//
//
//  Created by Giang Long Tran on 21.03.2023.
//

import Combine
import Foundation
import Wormhole

public class WormholeSendInputStateMachine: StateMachine, ObservableObject {
    public typealias State = WormholeSendInputState
    public typealias Action = WormholeSendInputAction
    public typealias Services = State.Service

    public var state: CurrentValueSubject<State, Never>
    public var services: State.Service

    var subscriptions: [AnyCancellable] = []

    public init(initialState: State, services: Services) {
        self.services = services
        state = .init(initialState)

        state
            .removeDuplicates()
            .sink { [weak self] state in
                guard let self else { return }
                Task {
                    if let action = await state.trigger(service: self.services) {
                        let _ = await self.accept(action: action)
                    }
                }
            }
            .store(in: &subscriptions)

        state
            .removeDuplicates()
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &subscriptions)
    }

    var currentTask: Task<Void, Never>?

    @discardableResult
    public func accept(action: WormholeSendInputAction) async -> State {
        if let currentTask {
            if state.value.isCancable() {
                currentTask.cancel()
            } else {
                let _ = await currentTask.value
            }
        }

        currentTask = Task {
            let nextState = await self.state.value.onAccept(action: action, service: self.services)

            if Task.isCancelled { return }

            currentTask = nil
            self.state.send(nextState)
        }

        return state.value
    }
}
