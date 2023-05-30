import Combine
import Foundation
import KeyAppKitCore

/// Default implementation of `BankTransferService`
public final class BankTransferServiceImpl {
    
    /// Repository that handle CRUD action for UserData
    public let repository: BankTransferUserDataRepository
    
    /// Subject that holds State with UserData stream
    public let subject = CurrentValueSubject<AsyncValueState<UserData>, Never>(
        AsyncValueState<UserData>(status: .ready, value: UserData(countryCode: nil, userId: nil, mobileVerified: false))
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
        fatalError("Not implemented")
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
    
    public func createUser(data: BankTransferRegistrationData) async throws {
        _ = try await repository.createUser(registrationData: data)
    }
    
    public func updateUser(data: BankTransferRegistrationData) async throws {
        try await repository.updateUser(registrationData: data)
    }
    
    public func getOTP() async throws {
        debugPrint("OTP is: 000000")
    }
    
    public func verify(OTP: String) async throws -> Bool {
        debugPrint("OTP is: \(OTP) == 000000")
        return OTP == "000000"
    }
    
    public func clearCache() async {
        await repository.clearCache()
    }
}
