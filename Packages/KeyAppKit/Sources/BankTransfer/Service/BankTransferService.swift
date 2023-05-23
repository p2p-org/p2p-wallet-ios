import Combine

public protocol BankTransferService {
    var userData: AnyPublisher<UserData, Never> { get }
    func reload() async

    func isBankTransferAvailable() -> Bool

    func getRegistrationData() async -> RegistrationData
    func save(regData: RegistrationData) async throws

    func getOTP() async throws
    func verify(OTP: String) async throws -> Bool
}
