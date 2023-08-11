import Combine
import KeyAppKitCore

public protocol BankTransferService<Provider> where Provider: BankTransferUserDataRepository {
    associatedtype Provider
    typealias WithdrawalInfo = Provider.WithdrawalInfo

    var state: AnyPublisher<AsyncValueState<UserData>, Never> { get }

    func reload() async

    // MARK: - Registration: Local actions

    func updateLocally(data: BankTransferRegistrationData) async throws
    func clearCache() async

    // MARK: - Registration: Remote actions

    func getRegistrationData() async throws -> BankTransferRegistrationData
    func createUser(data: BankTransferRegistrationData) async throws

    func verify(OTP: String) async throws
    func resendSMS() async throws

    func getKYCToken() async throws -> String

    func getWithdrawalInfo() async throws -> WithdrawalInfo?
    func saveWithdrawalInfo(info: WithdrawalInfo) async throws
}

public class AnyBankTransferService<Provider: BankTransferUserDataRepository> {
    public var value: BankTransferServiceImpl<Provider>

    public init(value: BankTransferServiceImpl<Provider>) {
        self.value = value
    }
}
