import Foundation

public actor MockStrigaLocalProvider: StrigaLocalProvider {
    
    // MARK: - Properties
    
    private var useCase: MockStrigaUseCase
    private var cachedRegistrationData: StrigaUserDetailsResponse?
    
    private var userId: String?
    
    // MARK: - Initializer
    
    public init(
        useCase: MockStrigaUseCase,
        hasCachedInput: Bool
    ) {
        self.useCase = useCase
        if hasCachedInput {
            var kyc: StrigaKYC.Status = .notStarted
            if .registeredAndVerifiedUser == useCase {
                kyc = .approved
            }
            
            cachedRegistrationData = StrigaUserDetailsResponse(
                firstName: "Local",
                lastName: "Provider",
                email: "local.provider@mocking.com",
                mobile: .init(countryCode: "1", number: "5853042520"),
                dateOfBirth: .init(year: 1986, month: 12, day: 1),
                address: .init(addressLine1: "Local street 12", addressLine2: nil, city: "Local Provider", postalCode: "12345", state: "Local Provider", country: "US"),
                occupation: .artEntertaiment,
                sourceOfFunds: .civilContract,
                placeOfBirth: nil,
                KYC: .init(status: kyc)
            )
        }
    }

    // MARK: - Methods

    public func getUserId() async -> String? {
        userId
    }
    
    public func saveUserId(_ id: String) async {
        userId = id
    }
    
    public func getCachedRegistrationData() async -> StrigaUserDetailsResponse? {
        cachedRegistrationData
    }
    
    public func save(registrationData: StrigaUserDetailsResponse) async throws {
        self.cachedRegistrationData = registrationData
    }
    
    public func clearRegistrationData() async {
        self.cachedRegistrationData = nil
        self.useCase = .unregisteredUser
    }
}
