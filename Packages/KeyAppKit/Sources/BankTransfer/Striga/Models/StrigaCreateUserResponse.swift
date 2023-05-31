import Foundation

public struct StrigaCreateUserResponse: Decodable {
    let userId: String
    let email: String
    let KYC: KYC
    
    public struct KYC: Decodable {
        public let status: String
        
        public var verified: Bool {
            // TODO: - Check later
            status != "NOT_STARTED"
        }
    }
}
