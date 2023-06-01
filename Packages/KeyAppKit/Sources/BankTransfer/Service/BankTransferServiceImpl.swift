import Combine
import Foundation
import KeyAppKitCore

/// Default implementation of `BankTransferService`
public final class BankTransferServiceImpl {
    
    /// Repository that handle CRUD action for UserData
    public let repository: BankTransferUserDataRepository
    
    /// Subject that holds State with UserData stream
    public let subject = CurrentValueSubject<AsyncValueState<UserData>, Never>(
        AsyncValueState<UserData>(status: .ready, value: .empty)
    )
    
    // MARK: - Initializers
    
    public init(repository: BankTransferUserDataRepository) {
        self.repository = repository
    }
}

extension BankTransferServiceImpl: BankTransferService {
    
    public var state: AnyPublisher<AsyncValueState<UserData>, Never> {
        subject.eraseToAnyPublisher()
    }
    
    public func save(userData: UserData) async throws {
        fatalError("Not implemented")
    }
    
    public func reload() async {
        // mark as loading
        subject.send(
            .init(
                status: .fetching,
                value: .empty,
                error: nil
            )
        )
        
        do {
            // registered user
            if let userId = try await repository.getUserId() {
                return try await handleRegisteredUser(userId: userId)
            }
            
            // unregistered user
            else {
                return try await handleUnregisteredUser()
            }
        } catch {
            return handleError(error: error)
        }
    }
    
    public func isBankTransferAvailable() -> Bool {
        fatalError("Not implemented")
    }

    public func getRegistrationData() async throws -> BankTransferRegistrationData {
        try await repository.getRegistrationData()
    }
    
    public func updateLocally(data: BankTransferRegistrationData) async throws {
        try await repository.updateUserLocally(registrationData: data)
    }
    
    public func createUser(data: BankTransferRegistrationData) async throws -> UserData {
        let response = try await repository.createUser(registrationData: data)
        return UserData(userId: response.userId, mobileVerified: false, kycVerified: response.KYC.verified)
    }
    
    public func updateUser(data: BankTransferRegistrationData) async throws {
        try await repository.updateUser(registrationData: data)
    }
    
    public func getOTP() async throws {
        fatalError("Not implemented")
    }
    
    public func verify(OTP: String) async throws -> Bool {
        fatalError("Not implemented")
    }
    
    public func resendSMS() async throws {
        guard let userId = subject.value.value.userId else { return }
        try await repository.resendSMS(userId: userId)
    }
    
    public func getKYCToken() async throws -> String {
        guard let userId = subject.value.value.userId else { throw BankTransferServiceError.missingUserId }
        return try await repository.getKYCToken(userId: userId)
    }
    
    public func clearCache() async {
        await repository.clearCache()
    }
    
    // MARK: - Helpers

    private func handleRegisteredUser(userId: String) async throws {
        // get user details, check kyc status
        let kycStatus = try await repository.getKYCStatus()
        
        // return value
        subject.send(
            .init(
                status: .ready,
                value: .init(
                    countryCode: nil,
                    userId: userId,
                    mobileVerified: true,
                    kycVerified: kycStatus.verified
                ),
                error: nil
            )
        )
    }
    
    private func handleUnregisteredUser() async throws {
        subject.send(
            .init(
                status: .ready,
                value: .init(
                    countryCode: nil,
                    userId: nil,
                    mobileVerified: false,
                    kycVerified: false
                ),
                error: nil
            )
        )
    }
    
    private func handleError(error: Error) {
        subject.send(
            .init(
                status: .ready,
                value: .empty,
                error: error
            )
        )
    }
}
