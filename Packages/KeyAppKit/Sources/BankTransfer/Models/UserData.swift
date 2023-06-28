public struct UserData: Codable {
    // MARK: - Properties

    public var userId: String?
    public var mobileVerified: Bool
    public var kycStatus: StrigaKYCStatus
    
    public var mobileNumber: String?

    public var wallets: [UserWallet]

    // MARK: - Initializer
    
    /// Private initializer for `UserData`
    private init(
        userId: String? = nil,
        mobileVerified: Bool,
        kycStatus: StrigaKYCStatus,
        mobileNumber: String?,
        wallets: [UserWallet]
    ) {
        // Method mark as private to prevent data erasing for countryCode, userId when calling init from outside.
        // Use `empty` and `updating()` instead of `init` when you want to modify something
        self.userId = userId
        self.mobileVerified = mobileVerified
        self.kycStatus = kycStatus
        self.mobileNumber = mobileNumber
        self.wallets = wallets
    }
    
    public static var empty: Self {
        .init(
            userId: nil,
            mobileVerified: false,
            kycStatus: .notStarted,
            mobileNumber: nil,
            wallets: []
        )
    }
    
    public func updated(
        userId: String? = nil,
        mobileVerified: Bool? = nil,
        kycStatus: StrigaKYCStatus? = nil,
        mobileNumber: String? = nil,
        wallets: [UserWallet]? = nil
    ) -> Self {
        .init(
            userId: userId ?? self.userId,
            mobileVerified: mobileVerified ?? self.mobileVerified,
            kycStatus: kycStatus ?? self.kycStatus,
            mobileNumber: mobileNumber ?? self.mobileNumber,
            wallets: wallets ?? self.wallets
        )
    }
}
