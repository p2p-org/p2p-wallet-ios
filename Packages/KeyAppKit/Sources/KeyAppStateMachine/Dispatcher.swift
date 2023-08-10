import Foundation

/// Dispatcher is an object that receive actions, currentState, define rules for converting them to a newState.
/// Dispatcher delegates work to handlers function inside BusinessLogic, await output and map them into a new state.
/// It will not handle any complex logics.
/// All complicated logics need to be handled in `BusinessLogic`.
public protocol Dispatcher<State, Action> {
    associatedtype State: KeyAppStateMachine.State
    associatedtype Action: KeyAppStateMachine.Action

    /// Asks the dispatcher whether to begin dispatching an action.
    func shouldBeginDispatching(currentAction: Action, newAction: Action, currentState: State) -> Bool

    /// Asks the dispatcher whether to cancel dispatching current action
    /// or wait for it to finish then perform new action.
    func shouldCancelCurrentAction(currentAction: Action, newAction: Action, currentState: State) -> Bool

    /// Dispatch an action and return new `State`
    func dispatch(
        action: Action,
        currentState: inout State,
        yield: (State) -> Void
    ) async
}
