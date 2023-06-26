import Foundation

public struct StrigaCreateUserRequest: Encodable {
    let firstName: String
    let lastName: String
    let email: String
    let mobile: Mobile
    let dateOfBirth: DateOfBirth?
    let address: Address?
    let occupation: StrigaUserIndustry?
    let sourceOfFunds: StrigaSourceOfFunds?
    let ipAddress: String?
    let placeOfBirth: String?
    let expectedIncomingTxVolumeYearly: String?
    let expectedOutgoingTxVolumeYearly: String?
    let selfPepDeclaration: Bool?
    let purposeOfAccount: String?
    
    struct Mobile: Encodable {
        let countryCode: String
        let number: String

        var isEmpty: Bool {
            countryCode.isEmpty || number.isEmpty
        }
    }
    
    struct DateOfBirth: Encodable {
        let year: Int?
        let month: Int?
        let day: Int?

        init(year: Int?, month: Int?, day: Int?) {
            self.year = year
            self.month = month
            self.day = day
        }

        init(year: String?, month: String?, day: String?) {
            if let year {
                self.year = Int(year)
            } else {
                self.year = nil
            }
            if let month {
                self.month = Int(month)
            } else {
                self.month = nil
            }
            if let day {
                self.day = Int(day)
            } else {
                self.day = nil
            }
        }
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
