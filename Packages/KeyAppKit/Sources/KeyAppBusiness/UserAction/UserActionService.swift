import Combine
import Foundation

public class UserActionService {
    var subscriptions: [AnyCancellable] = []

    /// List of consumers.
    var consumers: [any UserActionConsumer]

    /// Thread safe array update
    let accessQueue = DispatchQueue(label: "UserActionUpdateQueue", attributes: .concurrent)

    private let actionsSubject: CurrentValueSubject<[String: any UserAction], Never> = .init([:])

    public var actions: AnyPublisher<[any UserAction], Never> {
        actionsSubject
            .map { Array($0.values) }
            .eraseToAnyPublisher()
    }

    public init(consumers: [any UserActionConsumer]) {
        self.consumers = consumers

        for consumer in consumers {
            consumer.onUpdate.sink { [weak self] userActions in
                self?.update(actions: userActions)
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
    func update(actions: [any UserAction]) {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }

            var value = self.actionsSubject.value
            for action in actions {
                value[action.id] = action
            }

            self.actionsSubject.value = value
        }
    }

    /// Observer user action.
    public func observer<Action: UserAction>(action: Action) -> AnyPublisher<Action, Never> {
        actionsSubject
            .map { actions -> Action? in
                let action = actions[action.id]
                guard let action = action as? Action else { return nil }
                return action
            }
            .compactMap { $0 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public func observer(id: String) -> AnyPublisher<any UserAction, Never> {
        actionsSubject
            .map { actions -> (any UserAction)? in
                actions[id]
            }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    /// Get all actions.
    public func getActions() async -> [any UserAction] {
        await withCheckedContinuation { continuation in
            accessQueue.sync {
                continuation.resume(returning: Array(actionsSubject.value.values))
            }
        }
    }
}
