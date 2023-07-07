import Foundation
import KeyAppStateMachine

struct RecruitmentState: State {
    enum Status: Equatable {
        case initializing
        case sending
        case error(String)
        case completed
    }
    
    var applicantName: String
    var sendingStatus: Status
    
    static var initial: RecruitmentState {
        return RecruitmentState(
            applicantName: "",
            sendingStatus: .initializing
        )
    }
}

