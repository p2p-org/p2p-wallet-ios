import Foundation

public protocol StrigaRemoteProvider: AnyObject {
    func getUserId() async throws -> String?
    func getKYCStatus() async throws -> StrigaCreateUserResponse.KYC
    func getUserDetails(userId: String) async throws -> StrigaUserDetailsResponse
    func createUser(model: StrigaCreateUserRequest) async throws -> StrigaCreateUserResponse
    func verifyMobileNumber(userId: String, verificationCode: String) async throws
    func resendSMS(userId: String) async throws
}
