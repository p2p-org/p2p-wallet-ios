import Foundation

public struct UserDetailsResponse: RegistrationData {
    public let firstName: String
    public let lastName: String
    public let email: String
    public let mobile: Mobile
    public let dateOfBirth: DateOfBirth?
    public let address: Address?
    public let occupation: String?
    public let sourceOfFunds: String?
    public let placeOfBirth: String?
    
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
    
    public init(firstName: String, lastName: String, email: String, mobile: Mobile, dateOfBirth: DateOfBirth? = nil, address: Address? = nil, occupation: String? = nil, sourceOfFunds: String? = nil, placeOfBirth: String? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.mobile = mobile
        self.dateOfBirth = dateOfBirth
        self.address = address
        self.occupation = occupation
        self.sourceOfFunds = sourceOfFunds
        self.placeOfBirth = placeOfBirth
    }
}
