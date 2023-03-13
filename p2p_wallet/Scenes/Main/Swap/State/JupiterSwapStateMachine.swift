import Combine

public protocol StateMachine {
    var services: Services { get }
    func accept(action: Action, cancelPreviousAction: Bool) async -> State
}


actor JupiterSwapStateMachine: StateMachine {
    // MARK: - Properties

    private nonisolated let stateSubject: CurrentValueSubject<JupiterSwapState, Never>
    
    private var currentTask: Task<JupiterSwapState, Never>?
    private var currentAction: JupiterSwapAction?

    // MARK: - Public properties

    nonisolated var statePublisher: AnyPublisher<JupiterSwapState, Never> { stateSubject.eraseToAnyPublisher() }
    nonisolated var currentState: JupiterSwapState { stateSubject.value }

    nonisolated let services: JupiterSwapServices

    // MARK: - Initializer

    init(initialState: JupiterSwapState, services: JupiterSwapServices) {
        stateSubject = .init(initialState)
        self.services = services
    }
    
    // MARK: - Accept function

    nonisolated func accept(
        action newAction: JupiterSwapAction,
        cancelPreviousAction: Bool = true
    ) async -> JupiterSwapState {
        // cancel current action if needed
        if cancelPreviousAction {
            await currentTask?.cancel()
        }
        
        // dispatch new action (can be immediately or after current action)
        return await task(action: newAction)
    }
    
    // MARK: - Dispatching
    
    private func task(action: JupiterSwapAction) async -> JupiterSwapState {
        // save current action
        saveCurrentAction(action)
        
        // assign task
        currentTask = Task { await dispatch(action: action) }
        
        // append task to current stack
        return await currentTask!.value
    }
    
    @discardableResult
    private func dispatch(action: JupiterSwapAction) async -> JupiterSwapState {
        // save the last state
        let lastState = currentState
        
        // assert if action should be performed
        // for example if data is not changed, perform action is not needed
        guard JupiterSwapBusinessLogic.shouldPerformAction(
            state: currentState,
            action: action
        ) else {
            return currentState
        }
        
        // return the progress (loading state)
        if let progressState = JupiterSwapBusinessLogic.jupiterSwapProgressState(
            state: currentState, action: action
        ) {
            guard Task.isNotCancelled else { return lastState }
            stateSubject.send(progressState)
        }
        
        // perform the action
        guard Task.isNotCancelled else { return lastState }
        var newState = await JupiterSwapBusinessLogic.jupiterSwapBusinessLogic(
            state: currentState,
            action: action,
            services: services
        )

        // return the state
        guard Task.isNotCancelled else { return lastState }
        stateSubject.send(newState)
        
        // FIXME: - Create transaction if needed
        guard Task.isNotCancelled else { return lastState }
        newState = await JupiterSwapBusinessLogic.createTransaction(
            state: newState,
            services: services
        )
        
        guard Task.isNotCancelled else { return lastState }
        stateSubject.send(newState)
        
        return newState
    }
    
    // MARK: - Helpers

    private func saveCurrentAction(_ action: JupiterSwapAction) {
        currentAction = action
    }
}
