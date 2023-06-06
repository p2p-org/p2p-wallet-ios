import Foundation

public struct StrigaUserDetailsResponse: BankTransferRegistrationData {
    public let firstName: String
    public let lastName: String
    public let email: String
    public let mobile: Mobile
    public let dateOfBirth: DateOfBirth?
    public let address: Address?
    public let occupation: StrigaUserIndustry?
    public let sourceOfFunds: StrigaSourceOfFunds?
    public let placeOfBirth: String?
    public let KYC: StrigaKYC
    
    public struct Mobile: Codable {
        public let countryCode: String
        public let number: String
        
        public init(countryCode: String, number: String) {
            self.countryCode = countryCode
            self.number = number
        }
    }
    
    public struct DateOfBirth: Codable {
        public let year: Int?
        public let month: Int?
        public let day: Int?
        
        public init(year: Int?, month: Int?, day: Int?) {
            self.year = year
            self.month = month
            self.day = day
        }
        
        enum CodingKeys: CodingKey {
            case year
            case month
            case day
        }
        
        public init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
            
            let yearString = try container.decodeIfPresent(String.self, forKey: .year)
            self.year = yearString == nil ? nil: Int(yearString!)
            
            let monthString = try container.decodeIfPresent(String.self, forKey: .month)
            self.month = monthString == nil ? nil: Int(monthString!)
            
            let dayString = try container.decodeIfPresent(String.self, forKey: .day)
            self.day = dayString == nil ? nil: Int(dayString!)
        }
    }
    
    public struct Address: Codable {
        public let addressLine1: String?
        public let addressLine2: String?
        public let city: String?
        public let postalCode: String?
        public let state: String?
        public let country: String?
        
        public init(addressLine1: String?, addressLine2: String?, city: String?, postalCode: String?, state: String?, country: String?) {
            self.addressLine1 = addressLine1
            self.addressLine2 = addressLine2
            self.city = city
            self.postalCode = postalCode
            self.state = state
            self.country = country
        }
    }
    
    public init(firstName: String, lastName: String, email: String, mobile: Mobile, dateOfBirth: DateOfBirth? = nil, address: Address? = nil, occupation: StrigaUserIndustry? = nil, sourceOfFunds: StrigaSourceOfFunds? = nil, placeOfBirth: String? = nil, KYC: StrigaKYC) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.mobile = mobile
        self.dateOfBirth = dateOfBirth
        self.address = address
        self.occupation = occupation
        self.sourceOfFunds = sourceOfFunds
        self.placeOfBirth = placeOfBirth
        self.KYC = KYC
    }

    public static var empty: Self {
        StrigaUserDetailsResponse(
            firstName: "", lastName: "", email: "", mobile: Mobile(countryCode: "", number: ""), KYC: StrigaKYC(status: .notStarted, mobileVerified: false)
        )
    }

    public func updated(
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        mobile: Mobile? = nil,
        dateOfBirth: DateOfBirth?? = nil,
        address: Address?? = nil,
        occupation: StrigaUserIndustry?? = nil,
        sourceOfFunds: StrigaSourceOfFunds?? = nil,
        placeOfBirth: String?? = nil,
        KYC: StrigaKYC? = nil
    ) -> Self {
        StrigaUserDetailsResponse(
            firstName: firstName ?? self.firstName,
            lastName: lastName ?? self.lastName,
            email: email ?? self.email,
            mobile: mobile ?? self.mobile,
            dateOfBirth: dateOfBirth ?? self.dateOfBirth,
            address: address ?? self.address,
            occupation: occupation ?? self.occupation,
            sourceOfFunds: sourceOfFunds ?? self.sourceOfFunds,
            placeOfBirth: placeOfBirth ?? self.placeOfBirth,
            KYC: KYC ?? self.KYC
        )
    }
}
