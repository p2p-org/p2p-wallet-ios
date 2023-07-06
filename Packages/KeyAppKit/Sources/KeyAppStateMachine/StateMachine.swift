import Foundation
import Combine

/// A machine that consists of a set of states, actions, and a dispatcher that controls transition rules and define how the system transitions from one state to another based on the inputs it receives.
open class StateMachine<
    State: KeyAppStateMachine.State,
    Action: KeyAppStateMachine.Action,
    Dispatcher: KeyAppStateMachine.Dispatcher<State, Action>
> {

    // MARK: - Dependencies

    /// Dispatcher that controls dispatching actions
    private let dispatcher: Dispatcher

    // MARK: - Private properties
    
    /// Locker to prevent data race
    private let locker = NSLock()

    /// Subject that holds a stream of current state, start with an initial state
    private let stateSubject = CurrentValueSubject<State, Never>(.initial)

    /// Current active action
    private var currentAction: Action?

    /// Current working task
    private var currentTask: Task<Void, Never>?

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
        guard !dispatcher.shouldBeginDispatching(
            currentAction: currentAction,
            newAction: action,
            currentState: currentState
        ) else {
            return
        }
        
        // Check if new action should cancel current action
        if dispatcher.shouldCancelCurrentAction(
            currentAction: currentAction,
            newAction: action,
            currentState: currentState
        ) {
            // Cancel current action
            currentTask?.cancel()
        }
        
        // If current task is not cancelled
        else if let currentTask, currentTask.isCancelled == false {
            // Wait for current action to be completed
            Task { [unowned self] in
                await currentTask.value
                return accept(action: action)
            }
            return
        }
        
        // Dispatch action
        currentAction = action
        currentTask = Task { [unowned self] in
            // loading state whene action is about to be dispatched
            stateSubject.send(
                await dispatcher.actionWillBeginDispatching(
                    action: action,
                    currentState: currentState
                )
            )
            
            // check cancellation
            try? Task.checkCancellation()
            
            // dispatch action
            stateSubject.send(
                await dispatcher.dispatch(
                    action: action,
                    currentState: currentState
                )
            )
            
            // check cancellation
            try? Task.checkCancellation()
            
            // additional state when action is dispatched
            stateSubject.send(
                await dispatcher.actionDidEndDispatching(
                    action: action,
                    currentState: currentState
                )
            )
        }
    }
}
