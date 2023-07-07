import Foundation
import KeyAppStateMachine

class RecruitmentDispatcher: Dispatcher {
    // MARK: - Properties
    
    var shouldBeginDispatchingAnyAction: Bool = true
    var newActionShouldCancelPreviousAction: Bool = false
    let apiClient: APIClient

    // MARK: - Initializer

    init(
        shouldBeginDispatchingAnyAction: Bool = true,
        newActionShouldCancelPreviousAction: Bool = false,
        apiClient: APIClient
    ) {
        self.shouldBeginDispatchingAnyAction = shouldBeginDispatchingAnyAction
        self.newActionShouldCancelPreviousAction = newActionShouldCancelPreviousAction
        self.apiClient = apiClient
    }

    // MARK: - Methods

    func shouldBeginDispatching(
        currentAction: RecruitmentAction,
        newAction: RecruitmentAction,
        currentState: RecruitmentState
    ) -> Bool {
        shouldBeginDispatchingAnyAction
    }
    
    func shouldCancelCurrentAction(
        currentAction: RecruitmentAction,
        newAction: RecruitmentAction,
        currentState: RecruitmentState
    ) -> Bool {
        newActionShouldCancelPreviousAction
    }
    
    func actionWillBeginDispatching(
        action: RecruitmentAction,
        currentState: RecruitmentState
    ) async -> RecruitmentState {
        switch action {
        case .submitApplication(let applicantName):
            return currentState.modified {
                $0.sendingStatus = .sending
                $0.applicantName = applicantName
            }
        }
    }
    
    func dispatch(
        action: RecruitmentAction,
        currentState: RecruitmentState
    ) async -> RecruitmentState {
        switch action {
        case let .submitApplication(applicantName):
            do {
                try await RecruitmentBusinessLogic.sendApplicant(
                    applicantName: applicantName,
                    apiClient: apiClient
                )
                
                return currentState.modified {
                    $0.sendingStatus = .completed
                }
            } catch {
                return currentState.modified {
                    $0.sendingStatus = .error("\(error)")
                }
            }
        }
    }
    
    func actionDidEndDispatching(
        action: RecruitmentAction,
        currentState: RecruitmentState
    ) async -> RecruitmentState {
        // No additional state modifications in this example
        currentState
    }
}

