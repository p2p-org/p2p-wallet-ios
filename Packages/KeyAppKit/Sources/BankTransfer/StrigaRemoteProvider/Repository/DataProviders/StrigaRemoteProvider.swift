import Foundation

public protocol StrigaRemoteProvider: AnyObject {
    func getUserDetails(userId: String) async throws -> UserDetailsResponse
    func createUser(model: CreateUserRequest) async throws -> CreateUserResponse
    func verifyMobileNumber(userId: String, verificationCode: String) async throws
}
