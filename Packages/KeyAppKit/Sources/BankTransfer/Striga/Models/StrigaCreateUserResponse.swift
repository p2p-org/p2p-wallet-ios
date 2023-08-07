import Foundation

public struct StrigaCreateUserResponse: Decodable {
    let userId: String
    let email: String
    let KYC: KYC
}

public extension StrigaCreateUserResponse {
    struct KYC: Codable {
        public let status: StrigaKYCStatus

        public init(status: StrigaKYCStatus) {
            self.status = status
        }
    }
}
