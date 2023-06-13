import Foundation
import BankTransfer

extension StrigaKYCStatus {
    var isWaitingForUpload: Bool {
        self == .notStarted || self == .initiated || self == .rejected
    }
    
    var isBeingReviewed: Bool {
        self == .pendingReview || self == .onHold
    }
}
