import Foundation

public protocol IStrigaProvider: AnyObject {
    func getUserDetails(authHeader: StrigaEndpoint.AuthHeader, userId: String) async throws -> UserDetailsResponse
    func createUser(authHeader: StrigaEndpoint.AuthHeader, model: CreateUserRequest) async throws -> CreateUserResponse
    func verifyMobileNumber(authHeader: StrigaEndpoint.AuthHeader, userId: String, verificationCode: String) async throws
}
