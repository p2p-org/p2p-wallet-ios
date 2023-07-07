import Foundation
import KeyAppStateMachine

/// Action for a StateMachine
enum RecruitmentAction: Action {
    case submitApplication(applicantName: String)
//    case reviewApplication
//    case scheduleInterview
}
