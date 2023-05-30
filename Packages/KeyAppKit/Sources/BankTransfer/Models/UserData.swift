public struct UserData {
    public let countryCode: String?
    public let userId: String?
    public let mobileVerified: Bool
    public let kycVerified: Bool
    
    public static var empty: Self {
        .init(
            countryCode: nil,
            userId: nil,
            mobileVerified: false,
            kycVerified: false
        )
    }
}
