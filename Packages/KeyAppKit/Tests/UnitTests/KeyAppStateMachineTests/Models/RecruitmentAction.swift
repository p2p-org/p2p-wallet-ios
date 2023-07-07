import Foundation
import KeyAppStateMachine

enum RecruitmentAction: Action {
    case submitApplication(applicantName: String)
    case reviewApplication
    case scheduleInterview
}
