import Foundation
import KeyAppStateMachine

struct RecruitmentState: State {
    var applicantName: String
//    var isApplicationSubmitted: Bool
//    var isApplicationReviewed: Bool
//    var isInterviewScheduled: Bool
    
    static var initial: RecruitmentState {
        return RecruitmentState(
            applicantName: ""
//            isApplicationSubmitted: false,
//            isApplicationReviewed: false,
//            isInterviewScheduled: false
        )
    }
}

