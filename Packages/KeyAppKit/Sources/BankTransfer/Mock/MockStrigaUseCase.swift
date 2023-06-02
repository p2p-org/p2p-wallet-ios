import Foundation

public enum MockStrigaUseCase {
    case unregisteredUser(hasCachedInput: Bool)
    case registeredUserWithUnverifiedOTP(userId: String)
    case registeredUserWithoutKYC(userId: String, kycToken: String)
    case registeredAndVerifiedUser(userId: String)
}
