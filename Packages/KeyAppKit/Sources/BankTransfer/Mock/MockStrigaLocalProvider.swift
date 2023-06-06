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
                firstName: "",
                lastName: "",
                email: "test@test.test",
                mobile: StrigaUserDetailsResponse.Mobile(countryCode: "1", number: "5853042520"),
                dateOfBirth: nil,
                address: nil,
                occupation: nil,
                sourceOfFunds: nil,
                placeOfBirth: nil,
                KYC: StrigaKYC(
                    status: kyc,
                    mobileVerified: false
                )
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
