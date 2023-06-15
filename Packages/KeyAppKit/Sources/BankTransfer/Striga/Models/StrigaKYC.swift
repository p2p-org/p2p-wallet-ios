import Foundation

public struct StrigaKYC: Codable {
    public let status: StrigaKYCStatus
    public let mobileVerified: Bool
    
    public init(status: StrigaKYCStatus, mobileVerified: Bool) {
        self.status = status
        self.mobileVerified = mobileVerified
    }
}
