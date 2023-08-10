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
        yield: (inout RecruitmentState, (inout RecruitmentState) -> Void) -> Void
    ) async {
        switch action {
        case let .submitApplication(applicantName):
            // loading state
            var currentState = currentState

            yield(&currentState) {
                $0.sendingStatus = .sending
                $0.applicantName = applicantName
            }

            do {
                try await RecruitmentBusinessLogic.sendApplicant(
                    applicantName: applicantName,
                    apiClient: apiClient
                )

                yield(&currentState) {
                    $0.sendingStatus = .completed
                }
            } catch {
                yield(&currentState) {
                    $0.sendingStatus = .error("\(error)")
                }
            }
        }
    }
}
