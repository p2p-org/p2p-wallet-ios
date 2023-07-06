import Foundation
import Combine

/// A machine that consists of a set of states, actions, and a dispatcher that controls transition rules and define how the system transitions from one state to another based on the inputs it receives.
open class StateMachine<
    State: KeyAppStateMachine.State,
    Action: KeyAppStateMachine.Action,
    Dispatcher: KeyAppStateMachine.Dispatcher<State, Action>
> {
    // MARK: - Properties
    
    /// Dispatcher that controls dispatching actions
    private let dispatcher: Dispatcher

    /// Subject that holds a stream of current state, start with an initial state
    private let stateSubject = CurrentValueSubject<State, Never>(.initial)

    // MARK: - Initialization
    
    /// `StateMachine`'s initialization
    /// - Parameter dispatcher: Dispatcher that controls dispatching actions
    init(dispatcher: Dispatcher) {
        self.dispatcher = dispatcher
    }

    
}
