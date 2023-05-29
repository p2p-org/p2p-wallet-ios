import Foundation

public struct StrigaCreateUserRequest: Encodable {
    let firstName: String
    let lastName: String
    let email: String
    let mobile: Mobile
    let dateOfBirth: DateOfBirth?
    let address: Address?
    let occupation: String?
    let sourceOfFunds: String?
    let ipAddress: String?
    let placeOfBirth: String?
    let expectedIncomingTxVolumeYearly: String?
    let expectedOutgoingTxVolumeYearly: String?
    let selfPepDeclaration: Bool?
    let purposeOfAccount: String?
    
    struct Mobile: Encodable {
        let countryCode: String
        let number: String
    }
    
    struct DateOfBirth: Encodable {
        let year: Int?
        let month: Int?
        let day: Int?
    }
    
    struct Address: Encodable {
        let addressLine1: String?
        let addressLine2: String?
        let city: String?
        let postalCode: String?
        let state: String?
        let country: String?
    }
}
