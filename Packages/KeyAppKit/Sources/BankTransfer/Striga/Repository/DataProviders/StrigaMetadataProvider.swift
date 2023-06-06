import Foundation

public protocol StrigaMetadataProvider {
    func getStrigaMetadata() async throws -> StrigaMetadata?
}

public struct StrigaMetadata {
    public let userId: String?
    public let email: String
    public let phoneNumber: String
    
    public init(
        userId: String? = nil,
        email: String,
        phoneNumber: String
    ) {
        self.userId = userId
        self.email = email
        self.phoneNumber = phoneNumber
    }
}
