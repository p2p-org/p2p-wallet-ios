import Foundation

protocol AuthService {
    func socialSignIn(_ socialType: SocialType) async throws -> SocialAuthResponse
}
