import Onboarding
import Resolver

private enum Contants {
    static let tokenLifeTime = TimeInterval(60)
}

struct AuthServiceBridge: SocialAuthService {
    @Injected private var authService: AuthService
    @Injected private var jwtValidator: JWTTokenValidator

    func auth(type: SocialProvider) async throws -> (tokenID: String, email: String) {
        let authResult = try await authService.socialSignIn(type.socialType)
        return (tokenID: authResult.tokenID, email: authResult.email)
    }

    func isExpired(token: String) -> Bool {
        if let jwt = jwtValidator.decode(tokenID: token) {
            return jwt.iat.addingTimeInterval(Contants.tokenLifeTime) < Date()
        }
        return true
    }
}
