import Combine
import Foundation

/// A machine that consists of a set of states, actions, and a dispatcher that controls transition rules and define how
/// the system transitions from one state to another based on the inputs it receives.
public actor StateMachine<
    State: KeyAppStateMachine.State,
    Action: KeyAppStateMachine.Action,
    Dispatcher: KeyAppStateMachine.Dispatcher<State, Action>
> {
    // MARK: - Dependencies

    /// Dispatcher that controls dispatching actions
    private let dispatcher: Dispatcher

    /// Define if if logging available
    private let verbose: Bool

    // MARK: - Private properties

    /// Subject that holds a stream of current state, start with an initial state
    private let stateSubject = CurrentValueSubject<State, Never>(.initial)

    /// Current active action
    private var currentAction: Action?

    /// Current working task
    private var currentTask: Task<Void, Never>?

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
    public init(dispatcher: Dispatcher, verbose: Bool = false) {
        self.dispatcher = dispatcher
        self.verbose = verbose
    }

    // MARK: - Public methods

    /// Accept a new action
    /// - Parameter action: new action
    public func accept(action: Action) async {
        // Log
        logIfVerbose(message: "📲 Action accepted: \(action)")

        // If there is any performing action, task
        if let currentTask, let currentAction, currentTask.isCancelled == false {
            // Log
            logIfVerbose(message: "🚧 [AnotherInProgress] Another action in progress: \(currentAction)")

            // Check if action should be dispatched
            guard dispatcher.shouldBeginDispatching(
                currentAction: currentAction,
                newAction: action,
                currentState: currentState
            ) else {
                logIfVerbose(message: "🚧 ❌ [AnotherInProgress] Action refused: \(action)")
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
                logIfVerbose(message: "🚧 ❌ [AnotherInProgress] Action is marked as cancelled: \(currentAction)")
            }

            // Wait for current action to be completed
            else {
                // Log
                logIfVerbose(message: "🚧 🕑 [AnotherInProgress] Wait for current action to be completed...")

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
    private nonisolated func logIfVerbose(message: String) {
        guard verbose else { return }
        print("[StateMachine] \(message)")
    }

    /// Perform an action by delegating works to dispatcher
    private nonisolated func performAction(action: Action) async {
        // Log
        logIfVerbose(message: "🏗️ Action will begin dispatching: \(action)")

        // check cancellation
        guard !Task.isCancelled else {
            logIfVerbose(message: "❌ Action cancelled: \(action)")
            return
        }

        // Log
        logIfVerbose(message: "🚀 Action is being dispatched: \(action)")

        // get stream of states by dispatching action
        let stateStream = AsyncStream { continuation in
            Task {
                await dispatcher.dispatch(
                    action: action,
                    currentState: currentState
                ) { state in
                    continuation.yield(state)
                }

                continuation.finish()
            }
        }

        // Listen to stream and send state to user
        for await state in stateStream {
            // check cancellation
            guard !Task.isCancelled else {
                logIfVerbose(message: "❌ Action cancelled: \(action)")
                return
            }

            // send state
            stateSubject.send(state)
        }

        // Log
        logIfVerbose(message: "✅ Action did end dispatching: \(action)")
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
