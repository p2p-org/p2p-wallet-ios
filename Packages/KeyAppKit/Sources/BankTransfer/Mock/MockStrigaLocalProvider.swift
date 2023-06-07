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
                firstName: "Tester",
                lastName: "Tester1",
                email: "test@test.test",
                mobile: StrigaUserDetailsResponse.Mobile(countryCode: "+84", number: "+84776059617"),
                dateOfBirth: .init(year: 1984, month: 03, day: 12),
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
