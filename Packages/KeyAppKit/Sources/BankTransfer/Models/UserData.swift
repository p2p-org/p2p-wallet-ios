public struct UserData {
    public var countryCode: String?
    public var userId: String?
    public var mobileVerified: Bool
    public var kycVerified: Bool
    
    public static var empty: Self {
        .init(
            countryCode: nil,
            userId: nil,
            mobileVerified: false,
            kycVerified: false
        )
    }
}
