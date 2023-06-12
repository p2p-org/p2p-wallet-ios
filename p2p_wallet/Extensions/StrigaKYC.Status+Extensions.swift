import Foundation
import BankTransfer

extension StrigaKYC.Status {
    var isWaitingForUpload: Bool {
        self == .notStarted || self == .initiated || self == .rejected
    }
    
    var isBeingReviewed: Bool {
        self == .pendingReview || self == .onHold
    }
}
