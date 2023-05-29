public protocol BankTransferUserDataRepository {
    func getRegistrationData() async throws -> RegistrationData
 
    func createUser(registrationData: RegistrationData) async throws -> CreateUserResponse
    func updateUser(registrationData: RegistrationData) async throws

    func clearCache() async
}
