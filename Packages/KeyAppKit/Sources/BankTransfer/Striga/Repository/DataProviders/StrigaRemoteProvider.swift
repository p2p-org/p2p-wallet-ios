import Foundation

public protocol StrigaRemoteProvider: AnyObject {
    func getKYCStatus(userId: String) async throws -> StrigaKYC
    func getUserDetails(userId: String) async throws -> StrigaUserDetailsResponse
    func createUser(model: StrigaCreateUserRequest) async throws -> StrigaCreateUserResponse
    func verifyMobileNumber(userId: String, verificationCode: String) async throws
    func resendSMS(userId: String) async throws
    
    func getKYCToken(userId: String) async throws -> String
    
    func getAllWalletsByUser(userId: String, startDate: Date, endDate: Date, page: Int) async throws -> StrigaGetAllWalletsResponse

    /// - Send funds on chain to a whitelisted destination on the blockchain
    /// - Parameter userId: The Id of the user who is sending this transaction
    /// - Parameter sourceAccountId: The Id of the account to debit
    /// - Parameter whitelistedAddressId: The Id of the whitelisted destination
    /// - Parameter amount: The amount denominated in the smallest divisible unit of the sending currency. For example: cents or satoshis
    /// - SeeAlso: [Initiate Onchain Withdrawal](https://docs.striga.com/reference/initiate-onchain-withdrawal)
    func initiateOnChainWalletSend(
        userId: String,
        sourceAccountId: String,
        whitelistedAddressId: String,
        amount: String
    ) async throws -> StrigaWalletSendResponse

    func enrichAccount(userId: String, accountId: String) async throws -> StrigaEnrichedAccountResponse

    /// Resend OTP for transaction
    /// - Parameter userId: The Id of the user who is sending this transaction
    /// - Parameter challangeId: The challengeId that you received when initiating the transaction
    /// - SeeAlso: [Initiate Onchain Withdrawal](https://docs.striga.com/reference/initiate-onchain-withdrawal)
    func transactionResendOTP(userId: String, challangeId: String) async throws -> StrigaTransactionResendOTPResponse
}
