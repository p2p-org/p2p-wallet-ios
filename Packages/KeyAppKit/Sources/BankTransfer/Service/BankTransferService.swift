import Combine

public protocol BankTransferService {
    var userData: AnyPublisher<UserData, Never> { get }
    func save(userData: UserData) async throws
    func reload() async

    func isBankTransferAvailable() -> Bool
    
    // MARK: - Local actions

    func updateLocally(data: BankTransferRegistrationData) async throws
    func clearCache() async

    // MARK: - Remote actions

    func getRegistrationData() async throws -> BankTransferRegistrationData
    func createUser(data: BankTransferRegistrationData) async throws
    func updateUser(data: BankTransferRegistrationData) async throws

    func getOTP() async throws
    func verify(OTP: String) async throws -> Bool
}
