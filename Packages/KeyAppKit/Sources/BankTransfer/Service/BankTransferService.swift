import Combine

public protocol BankTransferService {
    var userData: AnyPublisher<UserData, Never> { get }
    func save(userData: UserData) throws
    func set(countryCode: String) throws
    func reload() async

    func isBankTransferAvailable() -> Bool

    func getRegistrationData() -> RegistrationData
    func save(data: RegistrationData) async throws
    func createUser(data: RegistrationData) async throws

    func getOTP() async throws
    func verify(OTP: String) async throws -> Bool

    func clearCache()
}
