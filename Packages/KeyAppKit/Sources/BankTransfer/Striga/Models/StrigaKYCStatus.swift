import Foundation

public enum StrigaKYCStatus: String, Codable {
    case notStarted = "NOT_STARTED"
    case initiated = "INITIATED" // The "Start KYC" endpoint has been called and the SumSub token has been fetched
    case pendingReview = "PENDING_REVIEW" // Documents have been submitted and are pending review
    case onHold = "ON_HOLD" // Requires manual review from the compliance team
    case approved = "APPROVED" // User approved
    case rejected = "REJECTED" // User rejected - Can be final or not
    case rejectedFinal = "REJECTED_FINAL"
}
