//
//  File.swift
//
//
//  Created by Giang Long Tran on 30.03.2023.
//

import Combine
import Foundation

public class UserActionService {
    var subscriptions: [AnyCancellable] = []

    /// List of consumers.
    var consumers: [any UserActionConsumer]

    /// Thread safe array update
    let accessQueue = DispatchQueue(label: "UserActionUpdateQueue", attributes: .concurrent)

    @Published public var actions: [any UserAction] = []

    public init(consumers: [any UserActionConsumer]) {
        self.consumers = consumers

        for consumer in consumers {
            consumer.onUpdate.sink { [weak self] userAction in
                self?.update(action: userAction)
            }
            .store(in: &subscriptions)

            consumer.start()
        }
    }

    /// Add user action to queue and execute.
    public func execute(action: any UserAction) {
        for consumer in consumers {
            consumer.process(action: action)
        }
    }

    public func handle(event: any UserActionEvent) {
        for consumer in consumers {
            consumer.handle(event: event)
        }
    }

    /// Internal method for updating action. The consumer will emits value and pass to this method.
    func update(action: any UserAction) {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }

            let idx = self.actions.firstIndex { $0.id == action.id }
            if let idx {
                self.actions[idx] = action
            } else {
                self.actions.append(action)
            }
        }
    }

    /// Observer user action.
    public func observer<Action: UserAction>(action: Action) -> AnyPublisher<Action, Never> {
        $actions
            .map { actions -> Action? in
                let action = actions.first { $0.id == action.id }
                guard let action = action as? Action else { return nil }
                return action
            }
            .compactMap { $0 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public func observer(id: String) -> AnyPublisher<any UserAction, Never> {
        $actions
            .map { actions -> (any UserAction)? in
                let action = actions.first { $0.id == id }
                guard let action else { return nil }
                return action
            }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    /// Get all actions.
    public func getActions() async -> [any UserAction] {
        await withCheckedContinuation { continuation in
            accessQueue.sync {
                continuation.resume(returning: actions)
            }
        }
    }
}
