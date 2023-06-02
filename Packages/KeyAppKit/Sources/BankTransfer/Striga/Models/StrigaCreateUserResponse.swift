import Foundation

public struct StrigaCreateUserResponse: Decodable {
    let userId: String
    let email: String
    let KYC: StrigaKYC
}

public struct StrigaKYC: Codable {
    public let status: Status
    public let mobileVerified: Bool
    
    public var approved: Bool {
        // TODO: - Check later
        status == .approved
    }
    
    public init(status: StrigaKYC.Status, mobileVerified: Bool) {
        self.status = status
        self.mobileVerified = mobileVerified
    }

    public enum Status: String, Codable {
        case notStarted = "NOT_STARTED"
        case initiated = "INITIATED" // The "Start KYC" endpoint has been called and the SumSub token has been fetched
        case pendingReview = "PENDING_REVIEW" // Documents have been submitted and are pending review
        case onHold = "ON_HOLD" // Requires manual review from the compliance team
        case approved = "APPROVED" // User approved
        case rejected = "REJECTED" // User rejected - Can be final or not
        case rejectedFinal = "REJECTED_FINAL"
    }
}
