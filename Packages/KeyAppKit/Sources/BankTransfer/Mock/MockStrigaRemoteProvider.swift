import Foundation

public final class MockStrigaRemoteProvider: StrigaRemoteProvider {
    
    public init() {
        
    }
    
    public func getUserId() async throws -> String? {
        "testUserId"
    }
    
    public func getUserDetails(userId: String) async throws -> StrigaUserDetailsResponse {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return .init(
            firstName: "Elon",
            lastName: "Musk",
            email: "elon.musk@starlink.com",
            mobile: .init(countryCode: "1", number: "5853042520"),
            dateOfBirth: .init(year: 1986, month: 12, day: 1),
            address: .init(addressLine1: "Elon str 12", addressLine2: nil, city: "New Your", postalCode: "12345", state: "New Your", country: "USA"),
            occupation: nil,
            sourceOfFunds: nil,
            placeOfBirth: nil
        )
    }
    
    public func createUser(model: StrigaCreateUserRequest) async throws -> StrigaCreateUserResponse {
        .init(
            userId: UUID().uuidString,
            email: model.email,
            KYC: .init(status: "done")
        )
    }
    
    public func verifyMobileNumber(userId: String, verificationCode: String) async throws {
        // all goods
    }
}
