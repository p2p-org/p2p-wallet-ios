import Foundation
import KeyAppStateMachine

struct RecruitmentDispatcher: Dispatcher {
    
    func shouldBeginDispatching(
        currentAction: RecruitmentAction?,
        newAction: RecruitmentAction,
        currentState: RecruitmentState
    ) -> Bool {
        // In this example, we allow all actions to be dispatched
        return true
    }
    
    func shouldCancelCurrentAction(currentAction: RecruitmentAction?, newAction: RecruitmentAction, currentState: RecruitmentState) -> Bool {
        // In this example, we don't cancel any ongoing actions
        return false
    }
    
    func actionWillBeginDispatching(
        action: RecruitmentAction,
        currentState: RecruitmentState
    ) async -> RecruitmentState {
        switch action {
        case let .submitApplication(applicantName):
            return currentState.modified {
                $0.applicantName = applicantName
                $0.isApplicationSubmitted = true
            }
        default:
            fatalError()
        }
    }
    
    func dispatch(
        action: RecruitmentAction,
        currentState: RecruitmentState
    ) async -> RecruitmentState {
        var newState = currentState
        switch action {
        case .reviewApplication:
            newState.isApplicationReviewed = true
        case .scheduleInterview:
            newState.isInterviewScheduled = true
        default:
            break
        }
        return newState
    }
    
    func actionDidEndDispatching(
        action: RecruitmentAction,
        currentState: RecruitmentState
    ) async -> RecruitmentState {
        // No additional state modifications in this example
        return currentState
    }
}

