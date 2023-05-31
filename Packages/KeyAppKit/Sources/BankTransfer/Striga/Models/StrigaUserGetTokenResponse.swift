import Foundation

public struct StrigaUserGetTokenResponse: Decodable {

    // MARK: - Properties

    public let provider: String
    public let token: String
    public let userId: String
    public let verificationLink: String

    // MARK: - Initializer

    public init(provider: String, token: String, userId: String, verificationLink: String) {
        self.provider = provider
        self.token = token
        self.userId = userId
        self.verificationLink = verificationLink
    }
}
