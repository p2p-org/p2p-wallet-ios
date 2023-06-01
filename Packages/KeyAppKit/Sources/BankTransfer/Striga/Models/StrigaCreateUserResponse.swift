import Foundation

public struct StrigaCreateUserResponse: Decodable {
    let userId: String
    let email: String
    let KYC: StrigaKYC
}

public struct StrigaKYC: Codable {
    public let status: Status
    
    public var verified: Bool {
        // TODO: - Check later
        status != .notStarted
    }

    public enum Status: String, Codable {
        case notStarted = "NOT_STARTED"
        case approved = "APPROVED"
    }
}

public extension StrigaKYC {
    static let approved = StrigaKYC(status: .approved)
    static let notStarted = StrigaKYC(status: .notStarted)
}
