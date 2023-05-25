import Combine

public protocol BankTransferService {
    var userData: AnyPublisher<UserData, Never> { get }
    func reload() async

    func isBankTransferAvailable() -> Bool

    func getRegistrationData() async throws -> RegistrationData
    func createUser(data: RegistrationData) async throws

    func getOTP() async throws
    func verify(OTP: String) async throws -> Bool
}
