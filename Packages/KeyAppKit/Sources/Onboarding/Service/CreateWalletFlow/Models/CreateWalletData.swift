public struct CreateWalletData: Codable, Equatable {
    public let ethAddress: String
    public let deviceShare: String
    public let wallet: OnboardingWallet
    public let security: SecurityData

    public let metadata: WalletMetaData
}
