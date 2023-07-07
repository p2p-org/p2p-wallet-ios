import Foundation
import KeyAppStateMachine

struct RecruitmentDispatcher: Dispatcher {
    var shouldBeginDispatchingAnyAction: Bool = true
    var newActionShouldCancelPreviousAction: Bool = false
    
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
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        return currentState
    }
    
    func dispatch(
        action: RecruitmentAction,
        currentState: RecruitmentState
    ) async -> RecruitmentState {
        // Network request
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        switch action {
        case let .submitApplication(applicantName):
            return currentState.modified {
                $0.applicantName = applicantName
                $0.isApplicationSubmitted = true
            }
        case .reviewApplication:
            return currentState.modified {
                $0.isApplicationReviewed = true
            }
        case .scheduleInterview:
            return currentState.modified {
                $0.isInterviewScheduled = true
            }
        }
    }
    
    func actionDidEndDispatching(
        action: RecruitmentAction,
        currentState: RecruitmentState
    ) async -> RecruitmentState {
        // No additional state modifications in this example
        return currentState
    }
}

