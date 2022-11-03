import Onboarding
import Resolver

struct AuthServiceBridge: SocialAuthService {
    @Injected private var authService: AuthService

    func auth(type: SocialProvider) async throws -> (tokenID: String, email: String) {
        let authResult = try await authService.socialSignIn(type.socialType)
        return (tokenID: authResult.tokenID, email: authResult.email)
    }
}
