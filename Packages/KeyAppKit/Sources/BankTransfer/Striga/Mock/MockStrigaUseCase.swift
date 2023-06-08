import Foundation

public enum MockStrigaUseCase: Equatable {
    case unregisteredUser
    case registeredUserWithUnverifiedOTP
    case registeredUserWithoutKYC
    case registeredAndVerifiedUser
}
