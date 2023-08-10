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
        currentAction _: RecruitmentAction,
        newAction _: RecruitmentAction,
        currentState _: RecruitmentState
    ) -> Bool {
        shouldBeginDispatchingAnyAction
    }

    func shouldCancelCurrentAction(
        currentAction _: RecruitmentAction,
        newAction _: RecruitmentAction,
        currentState _: RecruitmentState
    ) -> Bool {
        newActionShouldCancelPreviousAction
    }

    func dispatch(
        action: RecruitmentAction,
        currentState: RecruitmentState,
        yield: (RecruitmentState) -> Void
    ) async {
        switch action {
        case let .submitApplication(applicantName):
            // loading state
            var currentState = currentState.modified {
                $0.sendingStatus = .sending
                $0.applicantName = applicantName
            }

            // emit state
            yield(currentState)

            do {
                try await RecruitmentBusinessLogic.sendApplicant(
                    applicantName: applicantName,
                    apiClient: apiClient
                )

                currentState = currentState.modified {
                    $0.sendingStatus = .completed
                }
            } catch {
                currentState = currentState.modified {
                    $0.sendingStatus = .error("\(error)")
                }
            }

            // emit state
            yield(currentState)
        }
    }
}
