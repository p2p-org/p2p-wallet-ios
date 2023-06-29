import Combine
import KeyAppKitCore

public protocol BankTransferService {
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
    
    // MARK: - Claim
    func claimVerify(OTP: String, challengeId: String, ip: String) async throws
    func claimResendSMS(OTP: String, challengeId: String) async throws
}
