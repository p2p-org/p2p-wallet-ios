public struct UserData {
    // MARK: - Properties

    public var userId: String?
    public var mobileVerified: Bool
    public var kycVerified: Bool
    
    public var mobileNumber: String?

    // MARK: - Initializer
    
    /// Private initializer for `UserData`
    private init(userId: String? = nil, mobileVerified: Bool, kycVerified: Bool, mobileNumber: String?) {
        // Method mark as private to prevent data erasing for countryCode, userId when calling init from outside.
        // Use `empty` and `updating()` instead of `init` when you want to modify something
        self.userId = userId
        self.mobileVerified = mobileVerified
        self.kycVerified = kycVerified
        self.mobileNumber = mobileNumber
    }
    
    public static var empty: Self {
        .init(
            userId: nil,
            mobileVerified: false,
            kycVerified: false,
            mobileNumber: nil
        )
    }
    
    public func updated(
        userId: String? = nil,
        mobileVerified: Bool? = nil,
        kycVerified: Bool? = nil,
        mobileNumber: String? = nil
    ) -> Self {
        .init(
            userId: userId ?? self.userId,
            mobileVerified: mobileVerified ?? self.mobileVerified,
            kycVerified: kycVerified ?? self.kycVerified,
            mobileNumber: mobileNumber ?? self.mobileNumber
        )
    }
}
