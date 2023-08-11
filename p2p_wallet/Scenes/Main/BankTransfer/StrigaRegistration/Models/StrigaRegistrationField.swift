enum StrigaRegistrationField: Int, Identifiable {
    var id: Int { rawValue }

    case email
    case phoneNumber
    case firstName
    case surname
    case dateOfBirth
    case countryOfBirth
    case occupationIndustry
    case sourceOfFunds
    case country
    case city
    case addressLine
    case postalCode
    case stateRegion
}
