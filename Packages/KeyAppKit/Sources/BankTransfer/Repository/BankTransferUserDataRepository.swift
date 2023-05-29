public protocol BankTransferUserDataRepository {
    func getRegistrationData() async throws -> BankTransferRegistrationData
 
    func createUser(registrationData: BankTransferRegistrationData) async throws -> StrigaCreateUserResponse
    func updateUser(registrationData: BankTransferRegistrationData) async throws

    func updateUserLocally(registrationData: BankTransferRegistrationData) async throws
    func clearCache() async
}
