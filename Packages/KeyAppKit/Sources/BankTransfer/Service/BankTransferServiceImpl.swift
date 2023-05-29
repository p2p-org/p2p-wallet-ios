import Combine
import Foundation

/// Default implementation of `BankTransferService`
public final class BankTransferServiceImpl {
    
    /// Repository that handle CRUD action for UserData
    public let repository: BankTransferUserDataRepository
    
    /// Subject that holds UserData stream
    public let subject = CurrentValueSubject<UserData, Never>(
        UserData(countryCode: nil, userId: nil, mobileVerified: false)
    )
    
    // MARK: - Initializers
    
    public init(repository: BankTransferUserDataRepository) {
        self.repository = repository
    }
}

extension BankTransferServiceImpl: BankTransferService {
    public var userData: AnyPublisher<UserData, Never> {
        subject.eraseToAnyPublisher()
    }
    
    public func save(userData: UserData) async throws {
        fatalError("Not implemented")
    }
    
    public func reload() async {
        fatalError("Not implemented")
    }
    
    public func isBankTransferAvailable() -> Bool {
        fatalError("Not implemented")
    }

    public func getRegistrationData() async throws -> RegistrationData {
        try await repository.getRegistrationData()
    }
    
    public func save(data: RegistrationData) async throws {
        try await repository.updateUser(registrationData: data)
    }
    
    public func createUser(data: RegistrationData) async throws {
        _ = try await repository.createUser(registrationData: data)
    }
    
    public func getOTP() async throws {
        fatalError("Not implemented")
    }
    
    public func verify(OTP: String) async throws -> Bool {
        fatalError("Not implemented")
    }
    
    public func clearCache() async {
        await repository.clearCache()
    }
}
