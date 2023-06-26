import Combine
import KeyAppKitCore

public protocol BankTransferService {
    var state: AnyPublisher<AsyncValueState<UserData>, Never> { get }

    func reload() async
    
    // MARK: - Local actions

    func updateLocally(data: BankTransferRegistrationData) async throws
    func clearCache() async

    // MARK: - Remote actions

    func getRegistrationData() async throws -> BankTransferRegistrationData
    func createUser(data: BankTransferRegistrationData) async throws

    func verify(OTP: String) async throws
    func resendSMS() async throws
    
    func getKYCToken() async throws -> String

    // MARK: - Accounts data
    func getAllWalletsByUser() async throws -> UserAccounts
    func enrichAccount<T: Decodable>(accountId: String) async throws -> T
}
