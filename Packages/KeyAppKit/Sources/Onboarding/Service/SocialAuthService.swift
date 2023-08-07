public protocol SocialAuthService {
    func auth(type: SocialProvider) async throws -> (tokenID: String, email: String)
    func isExpired(token: String) -> Bool
}
