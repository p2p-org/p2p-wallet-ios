public struct RestoreWalletData: Codable, Equatable {
    public let ethAddress: String?
    public let wallet: OnboardingWallet
    public let security: SecurityData

    public let metadata: WalletMetaData?
}
