import Foundation

public final class MockStrigaRemoteProvider: StrigaRemoteProvider {
    // MARK: - Properties

    private var useCase: MockStrigaUseCase
    private let mockUserId: String
    private let mockKYCToken: String
    
    // MARK: - Initializer
    
    public init(
        useCase: MockStrigaUseCase,
        mockUserId: String,
        mockKYCToken: String
    ) {
        self.useCase = useCase
        self.mockUserId = mockUserId
        self.mockKYCToken = mockKYCToken
    }
    
    // MARK: - Methods

    public func getUserId() async throws -> String? {
        // Fake network request
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // return value
        switch useCase {
        case .unregisteredUser:
            return nil
        case .registeredUserWithUnverifiedOTP, .registeredUserWithoutKYC:
            return mockUserId
        case .registeredAndVerifiedUser:
            return mockUserId
        }
    }
    
    public func getKYCStatus() async throws -> StrigaKYC {
        // Fake network request
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let mobileVerified: Bool
        
        switch useCase {
        case .unregisteredUser, .registeredUserWithUnverifiedOTP:
            mobileVerified = false
        case .registeredUserWithoutKYC, .registeredAndVerifiedUser:
            mobileVerified = true
        }
        
        // return value
        switch useCase {
        case .unregisteredUser, .registeredUserWithUnverifiedOTP, .registeredUserWithoutKYC:
            return .init(status: .notStarted, mobileVerified: mobileVerified)
        case .registeredAndVerifiedUser:
            return .init(status: .approved, mobileVerified: mobileVerified)
        }
    }
    
    public func isMobileVerified() async throws -> Bool {
        // Fake network request
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // return value
        switch useCase {
        case .unregisteredUser, .registeredUserWithUnverifiedOTP:
            return false
        case .registeredUserWithoutKYC, .registeredAndVerifiedUser:
            return true
        }
    }
    
    public func getUserDetails(userId: String) async throws -> StrigaUserDetailsResponse {
        // Fake network request
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // return value
        return .init(
            firstName: "Remote",
            lastName: "Provider",
            email: "remote.provider@mocking.com",
            mobile: .init(countryCode: "1", number: "5853042520"),
            dateOfBirth: .init(year: 1986, month: 12, day: 1),
            address: .init(addressLine1: "Remote street 12", addressLine2: nil, city: "Remote Provider", postalCode: "12345", state: "Remote Provider", country: "USA"),
            occupation: nil,
            sourceOfFunds: nil,
            placeOfBirth: nil,
            KYC: try await getKYCStatus()
        )
    }
    
    public func createUser(model: StrigaCreateUserRequest) async throws -> StrigaCreateUserResponse {
        // Fake network request
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // return value
        useCase = .registeredUserWithUnverifiedOTP
        
        // return value
        return .init(
            userId: mockUserId,
            email: model.email,
            KYC: try await getKYCStatus()
        )
    }
    
    public func verifyMobileNumber(userId: String, verificationCode: String) async throws {
        // Fake network request
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // all goods
        // return value
        useCase = .registeredUserWithoutKYC
    }
    
    var invokedResendSMS = false
    var invokedResendSMSCount = 0
    var invokedResendSMSParameters: (userId: String, Void)?
    var invokedResendSMSParametersList = [(userId: String, Void)]()
    
    public func resendSMS(userId: String) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        // all goods
    }
    
    public func getKYCToken(userId: String) async throws -> String {
        // Fake network request
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // return value
        switch useCase {
        case .unregisteredUser, .registeredUserWithUnverifiedOTP, .registeredAndVerifiedUser:
            return ""
        case .registeredUserWithoutKYC:
            return mockKYCToken
        }
    }
}