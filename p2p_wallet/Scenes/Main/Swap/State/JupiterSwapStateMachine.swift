import Combine

actor JupiterSwapStateMachine {
    // MARK: - Nested type
    
    /// The cache that handle currentTask and currentAction
    /// Must be actor to make sure that currentTask and currentAction are thread-safe
    private actor Cache {
        /// Current executing task
        fileprivate var currentTask: Task<JupiterSwapState, Never>?
        /// Save the current task
        fileprivate func saveCurrentTask(_ task: Task<JupiterSwapState, Never>?) {
            currentTask = task
        }
    }
    
    // MARK: - Properties

    private nonisolated let stateSubject: CurrentValueSubject<JupiterSwapState, Never>
    private nonisolated let cache = Cache()

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

    @discardableResult
    nonisolated func accept(
        action newAction: JupiterSwapAction,
        waitForPreviousActionToComplete: Bool
    ) async -> JupiterSwapState {
        // cancel previous task when waitForPreviousActionToComplete = false
        if waitForPreviousActionToComplete == false {
            await cache.currentTask?.cancel()
        }
        
        // otherwise wait for current task to complete if it has not been cancelled
        else if await cache.currentTask?.isCancelled != true {
            _ = await cache.currentTask?.value
        }
        
        // create task to dispatch new action (can be immediately or after current action)
        let currentState = currentState
        let task = Task { [weak self] in
            guard let self else { return currentState}
            return await self.dispatch(action: newAction)
        }
        
        // save task to cache
        await cache.saveCurrentTask(task)
        
        // await it value
        return await task.value
    }
    
    // MARK: - Dispatching
    
    @discardableResult
    private func dispatch(action: JupiterSwapAction) async -> JupiterSwapState {
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
            stateSubject.send(progressState)
        }
        
        // perform the action
        guard Task.isNotCancelled else { return currentState }
        var newState = await JupiterSwapBusinessLogic.jupiterSwapBusinessLogic(
            state: currentState,
            action: action,
            services: services
        )

        // return the state
        guard Task.isNotCancelled else { return currentState }
        stateSubject.send(newState)
        
        // Create transaction if needed
        guard currentState.status == .creatingSwapTransaction else {
            return currentState
        }
        guard Task.isNotCancelled else { return currentState }
        newState = await JupiterSwapBusinessLogic.createTransaction(
            account: currentState.account,
            route: currentState.route,
            jupiterClient: services.jupiterClient
        )
        
        guard Task.isNotCancelled else { return currentState }
        stateSubject.send(newState)
        
        return newState
    }
}
