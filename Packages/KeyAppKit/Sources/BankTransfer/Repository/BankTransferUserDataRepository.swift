public protocol BankTransferUserDataRepository {
    associatedtype WithdrawalInfo

    func getUserId() async -> String?

    func getKYCStatus() async throws -> StrigaKYC

    func getRegistrationData() async throws -> BankTransferRegistrationData

    func createUser(registrationData: BankTransferRegistrationData) async throws -> StrigaCreateUserResponse

    func verifyMobileNumber(userId: String, verificationCode code: String) async throws
    func resendSMS(userId: String) async throws

    func getKYCToken(userId: String) async throws -> String

    func updateLocally(registrationData: BankTransferRegistrationData) async throws
    func updateLocally(userData: UserData) async throws
    func clearCache() async

    func getWallet(userId: String) async throws -> UserWallet?
    
    func withdrawalInfo() async throws -> WithdrawalInfo?
    func save(_ info: WithdrawalInfo) async throws
}
