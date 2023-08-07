import Foundation

public protocol CancableState {
    func isCancable() -> Bool
}

public protocol AutoTriggerState {
    associatedtype Services
    associatedtype Action

    func trigger(service: Services) async -> Action?
}

public protocol StateMachine<State, Action, Services> {
    associatedtype State
    associatedtype Action
    associatedtype Services

    var services: Services { get }

    func accept(action: Action) async -> State
}
