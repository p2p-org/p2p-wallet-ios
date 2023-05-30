import Foundation

public final class MockStrigaRemoteProvider: StrigaRemoteProvider {

    // MARK: - Properties
    
    private var userId: String?
    private let response: StrigaUserDetailsResponse = .init(
        firstName: "Remote",
        lastName: "Provider",
        email: "remote.provider@mocking.com",
        mobile: .init(countryCode: "1", number: "5853042520"),
        dateOfBirth: .init(year: 1986, month: 12, day: 1),
        address: .init(addressLine1: "Remote street 12", addressLine2: nil, city: "Remote Provider", postalCode: "12345", state: "Remote Provider", country: "USA"),
        occupation: nil,
        sourceOfFunds: nil,
        placeOfBirth: nil
    )
    private let useCase: MockStrigaUseCase
    
    // MARK: - Initializer
    
    public init(useCase: MockStrigaUseCase) {
        self.useCase = useCase
        
        switch useCase {
        case .unregisteredUser:
            userId = nil
        case .registeredUserWithoutKYC:
            userId = MockConstant.mockedUserId
        case .registeredAndVerifiedUser:
            userId = MockConstant.mockedUserId
        }
    }
    
    // MARK: - Methods

    public func getUserId() async throws -> String? {
        userId
    }
    
    public func getKYCStatus() async throws -> StrigaCreateUserResponse.KYC {
        fatalError()
    }
    
    public func getUserDetails(userId: String) async throws -> StrigaUserDetailsResponse {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return response
    }
    
    public func createUser(model: StrigaCreateUserRequest) async throws -> StrigaCreateUserResponse {
        let kyc: StrigaCreateUserResponse.KYC
        
        switch useCase {
        case .unregisteredUser:
            throw NSError(domain: "Striga", code: 1)
        case .registeredUserWithoutKYC:
            kyc = .init(status: "NOT_STARTED")
        case .registeredAndVerifiedUser:
            kyc = .init(status: "DONE")
        }
        
        return .init(
            userId: MockConstant.mockedUserId,
            email: model.email,
            KYC: kyc
        )
    }
    
    public func verifyMobileNumber(userId: String, verificationCode: String) async throws {
        // all goods
    }
}
