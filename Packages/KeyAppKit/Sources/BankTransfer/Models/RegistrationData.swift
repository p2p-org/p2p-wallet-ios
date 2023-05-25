import Foundation

public struct RegistrationData {
    public let firstName: String
    public let lastName: String
    public let email: String
    public let phoneCountryCode: String
    public let phoneNumber: String
    public let dateOfBirth: Date?
    public let placeOfBirth: String?
    public let occupation: String?
    public let placeOfLive: String?
    
    public init(
        firstName: String,
        lastName: String,
        email: String,
        phoneCountryCode: String,
        phoneNumber: String,
        dateOfBirth: Date?,
        placeOfBirth: String?,
        occupation: String?,
        placeOfLive: String?
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phoneCountryCode = phoneCountryCode
        self.phoneNumber = phoneNumber
        self.dateOfBirth = dateOfBirth
        self.placeOfBirth = placeOfBirth
        self.occupation = occupation
        self.placeOfLive = placeOfLive
    }
}

// MARK: - As Domain

extension UserDetailsResponse {
    func asDomain() -> RegistrationData {
        RegistrationData(
            firstName: firstName,
            lastName: lastName,
            email: email,
            phoneCountryCode: mobile.countryCode,
            phoneNumber: mobile.number,
            dateOfBirth: dateOfBirth?.asDate(),
            placeOfBirth: placeOfBirth,
            occupation: occupation,
            placeOfLive: nil
        )
    }
}

// MARK: - As Date

extension UserDetailsResponse.DateOfBirth {
    func asDate() -> Date? {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        let userCalendar = Calendar(identifier: .gregorian)
        return userCalendar.date(from: dateComponents)
    }
}
