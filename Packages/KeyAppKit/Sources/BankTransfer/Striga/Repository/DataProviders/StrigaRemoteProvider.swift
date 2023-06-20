import Foundation

public protocol StrigaRemoteProvider: AnyObject {
    func getKYCStatus(userId: String) async throws -> StrigaKYC
    func getUserDetails(userId: String) async throws -> StrigaUserDetailsResponse
    func createUser(model: StrigaCreateUserRequest) async throws -> StrigaCreateUserResponse
    func verifyMobileNumber(userId: String, verificationCode: String) async throws
    func resendSMS(userId: String) async throws
    
    func getKYCToken(userId: String) async throws -> String
    
    func getAllWalletsByUser(userId: String, startDate: Date, endDate: Date, page: Int) async throws -> StrigaGetAllWalletsResponse

    func initiateOnChainWalletSend(
        userId: String,
        sourceAccountId: String,
        whitelistedAddressId: String,
        amount: String
    ) async throws -> StrigaWalletSendResponse

    func enrichAccount(userId: String, accountId: String) async throws -> StrigaEnrichedAccountResponse
}
