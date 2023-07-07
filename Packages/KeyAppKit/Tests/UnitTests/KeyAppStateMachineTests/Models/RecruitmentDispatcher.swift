import Foundation
import KeyAppStateMachine

class RecruitmentDispatcher: Dispatcher {
    // MARK: - Properties
    
    var shouldBeginDispatchingAnyAction: Bool = true
    var newActionShouldCancelPreviousAction: Bool = false
    var delayInMilliseconds: UInt64

    // MARK: - Initializer

    init(
        shouldBeginDispatchingAnyAction: Bool = true,
        newActionShouldCancelPreviousAction: Bool = false,
        delayInMilliseconds: UInt64
    ) {
        self.shouldBeginDispatchingAnyAction = shouldBeginDispatchingAnyAction
        self.newActionShouldCancelPreviousAction = newActionShouldCancelPreviousAction
        self.delayInMilliseconds = delayInMilliseconds
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
        try? await sendFakeAPIRequest()
        return currentState
    }
    
    func dispatch(
        action: RecruitmentAction,
        currentState: RecruitmentState
    ) async -> RecruitmentState {
        // Network request
        try? await sendFakeAPIRequest()
        
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
    
    // MARK: - Helper

    private func sendFakeAPIRequest() async throws {
        try await Task.sleep(nanoseconds: delayInMilliseconds * 1_000_000)
    }
}

