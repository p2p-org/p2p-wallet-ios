public protocol BankTransferUserDataRepository {
    func getMetadata() async -> StrigaMetadata?
    
    func getKYCStatus() async throws -> StrigaKYC
    
    func getRegistrationData() async throws -> BankTransferRegistrationData
 
    func createUser(registrationData: BankTransferRegistrationData) async throws -> StrigaCreateUserResponse
    
    func verifyMobileNumber(userId: String, verificationCode code: String) async throws
    func resendSMS(userId: String) async throws
    
    func getKYCToken(userId: String) async throws -> String

    func updateUserLocally(registrationData: BankTransferRegistrationData) async throws
    func clearCache() async
}
