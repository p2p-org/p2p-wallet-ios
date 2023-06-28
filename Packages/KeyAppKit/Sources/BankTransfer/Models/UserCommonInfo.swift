public struct UserCommonInfo: Codable {
    public let firstName: String?
    public let lastName: String?
    public let nationality: String?
    public let placeOfBirth: String?
    public let dateOfBirth: DateOfBirth?

    public init(firstName: String?, lastName: String?, nationality: String?, placeOfBirth: String?, dateOfBirth: DateOfBirth?) {
        self.firstName = firstName
        self.lastName = lastName
        self.nationality = nationality
        self.placeOfBirth = placeOfBirth
        self.dateOfBirth = dateOfBirth
    }
}

public struct DateOfBirth: Codable {
    public let year: String?
    public let month: String?
    public let day: String?

    public init(year: String?, month: String?, day: String?) {
        self.year = year
        self.month = month
        self.day = day
    }
}
