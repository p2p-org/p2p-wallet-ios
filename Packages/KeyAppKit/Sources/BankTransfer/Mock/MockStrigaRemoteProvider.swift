import Foundation

public final class MockStrigaRemoteProvider: StrigaRemoteProvider {
    // MARK: - Properties
    
    private var userId: String?
    private let kycToken: String?
    private let response: StrigaUserDetailsResponse = .init(
        firstName: "Remote",
        lastName: "Provider",
        email: "remote.provider@mocking.com",
        mobile: .init(countryCode: "1", number: "5853042520"),
        dateOfBirth: .init(year: 1986, month: 12, day: 1),
        address: .init(addressLine1: "Remote street 12", addressLine2: nil, city: "Remote Provider", postalCode: "12345", state: "Remote Provider", country: "USA"),
        occupation: nil,
        sourceOfFunds: nil,
        placeOfBirth: nil,
        KYC: .notStarted
    )
    private let useCase: MockStrigaUseCase
    
    // MARK: - Initializer
    
    public init(useCase: MockStrigaUseCase) {
        self.useCase = useCase
        
        switch useCase {
        case .unregisteredUser:
            userId = nil
            kycToken = nil
        case let .registeredUserWithoutKYC(userId, kycToken):
            self.userId = userId
            self.kycToken = kycToken
        case let .registeredAndVerifiedUser(userId):
            self.userId = userId
            self.kycToken = nil
        }
    }
    
    // MARK: - Methods

    public func getUserId() async throws -> String? {
        userId
    }
    
    public func getKYCStatus() async throws -> StrigaKYC {
        let kyc: StrigaKYC
        
        switch useCase {
        case .unregisteredUser:
            throw NSError(domain: "Striga", code: 1)
        case .registeredUserWithoutKYC:
            kyc = .notStarted
        case .registeredAndVerifiedUser:
            kyc = .approved
        }
        
        return kyc
    }
    
    public func getUserDetails(userId: String) async throws -> StrigaUserDetailsResponse {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return response
    }
    
    public func createUser(model: StrigaCreateUserRequest) async throws -> StrigaCreateUserResponse {
        .init(
            userId: userId!,
            email: model.email,
            KYC: try await getKYCStatus()
        )
    }
    
    public func verifyMobileNumber(userId: String, verificationCode: String) async throws {
        // all goods
    }
    
    var invokedResendSMS = false
    var invokedResendSMSCount = 0
    var invokedResendSMSParameters: (userId: String, Void)?
    var invokedResendSMSParametersList = [(userId: String, Void)]()
    
    public func resendSMS(userId: String) async throws {
        
    }
    
    public func getKYCToken(userId: String) async throws -> String {
        kycToken!
    }
}
