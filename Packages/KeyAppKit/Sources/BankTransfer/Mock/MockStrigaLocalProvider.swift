import Foundation

public actor MockStrigaLocalProvider: StrigaLocalProvider {

    // MARK: - Properties

    private var userId: String?
    private var cachedRegistrationData: StrigaUserDetailsResponse?

    // MARK: - Initializer

    public init(useCase: MockStrigaUseCase) {
        var kyc: StrigaKYC.Status = .notStarted
        if case .registeredAndVerifiedUser(_) = useCase {
            kyc = .approved
        }
        
        var defaultCachedInput = StrigaUserDetailsResponse(
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
        
        switch useCase {
        case let .unregisteredUser(hasCachedInput):
            userId = nil
            cachedRegistrationData = hasCachedInput ? defaultCachedInput: nil
        case let .registeredUserWithUnverifiedOTP(userId):
            self.userId = userId
            cachedRegistrationData = defaultCachedInput
        case let .registeredUserWithoutKYC(userId, _):
            self.userId = userId
            cachedRegistrationData = defaultCachedInput
        case let .registeredAndVerifiedUser(userId):
            self.userId = userId
            cachedRegistrationData = defaultCachedInput
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
        self.userId = nil
    }
}
