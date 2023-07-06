import Foundation
import Combine

/// A machine that consists of a set of states, actions, and a dispatcher that controls transition rules and define how the system transitions from one state to another based on the inputs it receives.
open class StateMachine<
    State: KeyAppStateMachine.State,
    Action: KeyAppStateMachine.Action,
    Dispatcher: KeyAppStateMachine.Dispatcher<State, Action>
> {
    // MARK: - Private properties
    
    /// Locker to handle data write
    private let locker = NSLock()
    
    /// Dispatcher that controls dispatching actions
    private let dispatcher: Dispatcher

    /// Subject that holds a stream of current state, start with an initial state
    private let stateSubject = CurrentValueSubject<State, Never>(.initial)

    /// Current active action
    private var currentAction: Action?

    // MARK: - Public properties
    
    /// Publisher that emit a stream of current state to listener
    public var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    /// The current state of the machine
    public var currentState: State {
        stateSubject.value
    }

    // MARK: - Initialization
    
    /// `StateMachine`'s initialization
    /// - Parameter dispatcher: Dispatcher that controls dispatching actions
    init(dispatcher: Dispatcher) {
        self.dispatcher = dispatcher
    }

    // MARK: - Public methods
    
    /// Accept a new action
    /// - Parameter action: new action
    open func accept(action: Action) {
        // Lock
        locker.lock(); defer { locker.unlock() }
        
        // Check if action should be dispatched
        guard dispatcher.shouldBeginDispatching(action: action, currentState: currentState)
        else {
            return
        }
        
        // Check if new action should cancel current action
        dispatcher.shouldCancelCurrentAction(currentAction: currentAction, newAction: action, currentState: currentState)
    }
}
