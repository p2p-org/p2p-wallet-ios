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
    
    public func getKYCStatus(userId: String) async throws -> StrigaKYC {
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
    
    public func getUserDetails(userId: String) async throws -> StrigaUserDetailsResponse {
        // Fake network request
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // return value
        return .init(
            firstName: "Remote",
            lastName: "Provider",
            email: "remote.provider@mocking.com",
            mobile: .init(countryCode: "1", number: "5853042520"),
            dateOfBirth: .init(year: "1986", month: "12", day: "1"),
            address: .init(addressLine1: "Remote street 12", addressLine2: nil, city: "Remote Provider", postalCode: "12345", state: "Remote Provider", country: "USA"),
            occupation: nil,
            sourceOfFunds: nil,
            placeOfBirth: nil,
            KYC: try await getKYCStatus(userId: mockUserId)
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
            KYC: .init(
                status: .notStarted
            )
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
    
    public func getAllWalletsByUser(userId: String, startDate: Date, endDate: Date, page: Int) async throws -> StrigaGetAllWalletsResponse {
        fatalError("Implementing")
    }
    
    public func enrichAccount(userId: String, accountId: String) async throws -> StrigaEnrichedAccountResponse {
        fatalError("Implementing")
    }

    public func initiateOnChainWalletSend(userId: String, sourceAccountId: String, whitelistedAddressId: String, amount: String) async throws -> StrigaWalletSendResponse {
        fatalError("Implementing")
    }

    public func transactionResendOTP(userId: String, challangeId: String) async throws -> StrigaTransactionResendOTPResponse {
        fatalError("Implementing")
    }
}
