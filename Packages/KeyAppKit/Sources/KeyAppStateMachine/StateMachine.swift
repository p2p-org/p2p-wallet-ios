import Combine
import Foundation

/// A machine that consists of a set of states, actions, and a dispatcher that controls transition rules and define how
/// the system transitions from one state to another based on the inputs it receives.
public actor StateMachine<Dispatcher> where Dispatcher: KeyAppStateMachine.Dispatcher {
    public typealias State = Dispatcher.State
    public typealias Action = Dispatcher.Action

    // MARK: - Dependencies

    /// Dispatcher that controls dispatching actions
    let dispatcher: Dispatcher

    /// Define if if logging available
    let verbose: Bool

    // MARK: - Private properties

    /// Subject that holds a stream of current state, start with an initial state
    let stateSubject: CurrentValueSubject<State, Never>

    /// Current active action
    var currentAction: Action?

    /// Current working task
    var currentTask: Task<Void, Never>?

    var subscriptions: [AnyCancellable] = []

    // MARK: - Public properties

    /// Publisher that emit a stream of current state to listener
    public nonisolated var statePublisher: AnyPublisher<State, Never> {
        stateSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// The current state of the machine
    public nonisolated var currentState: State {
        stateSubject.value
    }

    // MARK: - Initialization

    /// `StateMachine`'s initialization
    /// - Parameter dispatcher: Dispatcher that controls dispatching actions
    /// - Parameter verbose: Define if if logging available
    public init(initialState: State, dispatcher: Dispatcher, verbose: Bool = false) {
        stateSubject = CurrentValueSubject<State, Never>(initialState)
        self.dispatcher = dispatcher
        self.verbose = verbose

        stateSubject.sink { state in
            dispatcher.onEnter(currentState: state)
        }.store(in: &subscriptions)

        log(message: "🚧 Initialising with state: \(initialState)")
    }

    // MARK: - Public methods

    /// Accept a new action
    /// - Parameter action: new action
    public func accept(action: Action) async {
        // Log
        log(message: "📲 Action accepted: \(action)")

        // If there is any performing action, task
        if let currentTask, let currentAction, currentTask.isCancelled == false {
            // Log
            log(message: "🚧 [AnotherInProgress] Another action in progress: \(currentAction)")

            // Check if action should be dispatched
            guard dispatcher.shouldBeginDispatching(
                currentAction: currentAction,
                newAction: action,
                currentState: currentState
            ) else {
                log(message: "🚧 ❌ [AnotherInProgress] Action refused: \(action)")
                return
            }

            // Check if new action should cancel current action
            if dispatcher.shouldCancelCurrentAction(
                currentAction: currentAction,
                newAction: action,
                currentState: currentState
            ) {
                // Cancel current action
                currentTask.cancel()

                // Log
                log(message: "🚧 ❌ [AnotherInProgress] Action is marked as cancelled: \(currentAction)")
            }

            // Wait for current action to be completed
            else {
                // Log
                log(message: "🚧 🕑 [AnotherInProgress] Wait for current action to be completed...")

                // Wait
                await currentTask.value
            }
        }

        // Dispatch action
        saveCurrentAction(action)
        saveCurrentTask(.init { [unowned self] in
            // perform task
            await performAction(action: action)

            // remove current task / action
            saveCurrentAction(nil)
            saveCurrentTask(nil)
        })
    }

    // MARK: - Private methods

    /// Log an event
    private nonisolated func log(message: String) {
        guard verbose else { return }
        print("[StateMachine] \(message)")
    }

    /// Perform an action by delegating works to dispatcher
    private nonisolated func performAction(action: Action) async {
        // Log
        log(message: "🏗️ Action will begin dispatching: \(action)")

        if let intermediateState = await dispatcher.actionWillBeginDispatching(
            action: action,
            currentState: currentState
        ) {
            // loading state whene action is about to be dispatched if it is needed
            stateSubject.send(intermediateState)
        }

        // check cancellation
        guard !Task.isCancelled else {
            log(message: "❌ Action cancelled: \(action)")
            return
        }

        // Log
        log(message: "🚀 Action is being dispatched: \(action)")

        // dispatch action
        stateSubject.send(
            await dispatcher.dispatch(
                action: action,
                currentState: currentState
            )
        )

        // check cancellation
        guard !Task.isCancelled else {
            log(message: "❌ Action cancelled: \(action)")
            return
        }

        // Log
        log(message: "✅ Action did end dispatching: \(action)")

        if let endState = await dispatcher.actionDidEndDispatching(
            action: action,
            currentState: currentState
        ) {
            // additional state when action is dispatched if it is needed
            stateSubject.send(endState)
        }
    }

    /// Save current action
    private func saveCurrentAction(_ action: Action?) {
        currentAction = action
    }

    /// Save current task
    private func saveCurrentTask(_ task: Task<Void, Never>?) {
        currentTask = task
    }
}
