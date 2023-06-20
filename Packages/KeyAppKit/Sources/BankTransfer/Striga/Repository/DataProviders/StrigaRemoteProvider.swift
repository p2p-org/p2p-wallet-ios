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
    /// - SeeAlso: [Resend OTP for transaction](https://docs.striga.com/reference/resend-otp-for-transaction)
    func transactionResendOTP(userId: String, challangeId: String) async throws -> StrigaTransactionResendOTPResponse

    /// Your API calls will appear here. Make a request to get started!
    /// - Parameter userId: The Id of the user who is sending this transaction
    /// - Parameter challangeId: The challengeId that you received when initiating the transaction
    /// - Parameter code: 6 characters code. Default code for sandbox "123456".
    /// - Parameter ip: IP address collected as the IP address from which the End User is making the withdrawal request. IMPORTANT - This will be a required parameter from the 15th of June 2023 and is optional until then.
    /// - SeeAlso: [Confirm transaction with OTP](https://docs.striga.com/reference/confirm-transaction-with-otp)
    func transactionConfirmOTP(
        userId: String,
        challangeId: String,
        code: String,
        ip: String
    ) async throws -> StrigaTransactionConfirmOTPResponse
}
