import Send // TODO: I will extract StateMachine in core module inside Key App Kit
import Combine

actor JupiterSwapStateMachine: StateMachine {
    private nonisolated let stateSubject: CurrentValueSubject<JupiterSwapState, Never>

    nonisolated var statePublisher: AnyPublisher<JupiterSwapState, Never> { stateSubject.eraseToAnyPublisher() }
    nonisolated var currentState: JupiterSwapState { stateSubject.value }

    nonisolated let services: JupiterSwapServices

    init(initialState: JupiterSwapState, services: JupiterSwapServices) {
        stateSubject = .init(initialState)
        self.services = services
    }

    @discardableResult
    func accept(action: JupiterSwapAction) async -> JupiterSwapState {
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
        var newState = await JupiterSwapBusinessLogic.jupiterSwapBusinessLogic(
            state: currentState,
            action: action,
            services: services
        )

        // return the state
        stateSubject.send(newState)
        
        // FIXME: - Create transaction if needed
        newState = await JupiterSwapBusinessLogic.createTransaction(
            state: newState,
            services: services
        )
        
        stateSubject.send(newState)
        
        return newState
    }
}
