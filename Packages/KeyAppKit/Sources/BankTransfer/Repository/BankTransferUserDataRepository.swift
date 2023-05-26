protocol BankTransferUserDataRepository {
    var userData: UserData? { get }
    func reload() async
    func save(userData: UserData) async
 
    func save(registrationData: RegistrationData) async
    func getRegistrationData() async -> RegistrationData

    func clearCache() async
}
