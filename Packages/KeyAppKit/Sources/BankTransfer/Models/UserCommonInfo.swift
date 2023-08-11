public struct UserCommonInfo: Codable {
    public let firstName: String?
    public let lastName: String?
    public let placeOfBirth: String? // alpha3Code
    public let dateOfBirth: DateOfBirth?
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
