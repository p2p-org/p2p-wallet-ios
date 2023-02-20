import Send // TODO: I will extract StateMachine in core module inside Key App Kit
import Combine

actor JupiterSwapStateMachine: StateMachine {
    typealias Action = JupiterSwapAction
    typealias Services = JupiterSwapServices
    typealias State = JupiterSwapState

    private nonisolated let stateSubject: CurrentValueSubject<JupiterSwapState, Never>

    nonisolated var statePublisher: AnyPublisher<JupiterSwapState, Never> { stateSubject.eraseToAnyPublisher() }
    nonisolated var currentState: JupiterSwapState { stateSubject.value }

    nonisolated let services: JupiterSwapServices

    init(initialState: JupiterSwapState, services: JupiterSwapServices) {
        stateSubject = .init(initialState)
        self.services = services
    }

    func accept(action: JupiterSwapAction) async -> JupiterSwapState {
        if let progressState = JupiterSwapBusinessLogic.jupiterSwapProgressState(state: currentState, action: action) {
            stateSubject.send(progressState)
        }
        let newState = await JupiterSwapBusinessLogic.jupiterSwapBusinessLogic(state: currentState, action: action, services: services)
        stateSubject.send(newState)
        return newState
    }
}
