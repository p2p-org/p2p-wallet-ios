import Foundation

public actor MockStrigaLocalProvider: StrigaLocalProvider {
    private var userId: String?
    private var cachedRegistrationData: StrigaUserDetailsResponse? = .init(
        firstName: "Local",
        lastName: "Provider",
        email: "local.provider@mocking.com",
        mobile: .init(countryCode: "1", number: "5853042520"),
        dateOfBirth: .init(year: 1986, month: 12, day: 1),
        address: .init(addressLine1: "Local street 12", addressLine2: nil, city: "Local Provider", postalCode: "12345", state: "Local Provider", country: "USA"),
        occupation: nil,
        sourceOfFunds: nil,
        placeOfBirth: nil
    )
    
    public init() {}
    
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
