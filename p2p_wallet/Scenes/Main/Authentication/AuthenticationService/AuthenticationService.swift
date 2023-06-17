import Foundation

/// Service that manages Authentication
protocol AuthenticationService {
    func shouldAuthenticateUser() -> Bool
}

/// Default implementation of AuthService
// final class AuthServiceImpl: AuthService {
// }
