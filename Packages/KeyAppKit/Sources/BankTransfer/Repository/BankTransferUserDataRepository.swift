public protocol BankTransferUserDataRepository {
    func getUserId() async throws -> String?
    
    func getKYCStatus() async throws -> StrigaKYC.Status
    
    func getRegistrationData() async throws -> BankTransferRegistrationData
 
    func createUser(registrationData: BankTransferRegistrationData) async throws -> StrigaCreateUserResponse
    func updateUser(registrationData: BankTransferRegistrationData) async throws
    func resendSMS(userId: String) async throws
    
    func getKYCToken(userId: String) async throws -> String

    func updateUserLocally(registrationData: BankTransferRegistrationData) async throws
    func clearCache() async
}
