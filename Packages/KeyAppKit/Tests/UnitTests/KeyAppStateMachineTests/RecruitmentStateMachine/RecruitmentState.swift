import Foundation
import KeyAppStateMachine

struct RecruitmentState: State {
    // MARK: - Properties
    var applicantName: String
    var sendingStatus: Status
    
    static var initial: RecruitmentState {
        return RecruitmentState(
            applicantName: "",
            sendingStatus: .initializing
        )
    }
}

// MARK: - Nested type

extension RecruitmentState {
    enum Status: Equatable {
        case initializing
        case sending
        case error(String)
        case completed
    }
}
