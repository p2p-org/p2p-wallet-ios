import Foundation

public enum MockStrigaUseCase {
    case unregisteredUser(hasCachedInput: Bool)
    case registeredUserWithoutKYC
    case registeredAndVerifiedUser
}

public enum MockConstant {
    static let mockedUserId = "mockedUserId"
}
