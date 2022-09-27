import Onboarding
import Resolver
import SwiftJWT

private enum Contants {
    static let tokenLifeTime = TimeInterval(60)
}

struct AuthServiceBridge: SocialAuthService {
    @Injected var authService: AuthService

    func auth(type: SocialProvider) async throws -> (tokenID: String, email: String) {
        let authResult = try await authService.socialSignIn(type.socialType)
        return (tokenID: authResult.tokenID, email: authResult.email)
    }

    func isExpired(token: String) -> Bool {
        if let jwt = JWTTokenValidator().decode(tokenID: token) {
            return jwt.iat.addingTimeInterval(Contants.tokenLifeTime) < Date()
        }
        return true
    }
}
