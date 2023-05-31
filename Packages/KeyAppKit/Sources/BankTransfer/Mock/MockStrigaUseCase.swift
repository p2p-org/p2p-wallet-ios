import Foundation

public enum MockStrigaUseCase {
    case unregisteredUser(hasCachedInput: Bool)
    case registeredUserWithoutKYC(userId: String, kycToken: String)
    case registeredAndVerifiedUser(userId: String)
}
