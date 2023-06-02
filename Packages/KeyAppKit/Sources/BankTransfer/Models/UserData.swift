public struct UserData {
    // MARK: - Properties

    public var countryCode: String?
    public var userId: String?
    public var mobileVerified: Bool
    public var kycVerified: Bool

    // MARK: - Initializer
    
    /// Private initializer for `UserData`
    private init(countryCode: String? = nil, userId: String? = nil, mobileVerified: Bool, kycVerified: Bool) {
        // Method mark as private to prevent data erasing for countryCode, userId when calling init from outside.
        // Use `empty` and `updating()` instead of `init` when you want to modify something
        self.countryCode = countryCode
        self.userId = userId
        self.mobileVerified = mobileVerified
        self.kycVerified = kycVerified
    }
    
    public static var empty: Self {
        .init(
            countryCode: nil,
            userId: nil,
            mobileVerified: false,
            kycVerified: false
        )
    }
    
    public func updating(
        countryCode: String? = nil,
        userId: String? = nil,
        mobileVerified: Bool? = nil,
        kycVerified: Bool? = nil
    ) -> Self {
        .init(
            countryCode: countryCode ?? self.countryCode,
            userId: userId ?? self.userId,
            mobileVerified: mobileVerified ?? self.mobileVerified,
            kycVerified: kycVerified ?? self.kycVerified
        )
    }
}
