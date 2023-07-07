import Foundation
import KeyAppStateMachine

/// Action for a RecruitmentAction
/// Assume that there is only 1 application accepted, and we ONLY get last application, cancel all previous
enum RecruitmentAction: Action {
    case submitApplication(applicantName: String)
//    case reviewApplication
//    case scheduleInterview
}
