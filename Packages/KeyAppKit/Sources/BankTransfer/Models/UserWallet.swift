public struct UserWallet: Codable {
    public let walletId: String
    public var accounts: UserAccounts

    init(_ wallet: StrigaWallet) {
        var eur: EURUserAccount?
        if let eurAccount = wallet.accounts.eur {
            eur = EURUserAccount(
                accountID: eurAccount.accountID,
                currency: eurAccount.currency,
                createdAt: eurAccount.createdAt,
                enriched: false
            )
        }
        var usdc: USDCUserAccount?
        if let usdcAccount = wallet.accounts.usdc {
            usdc = USDCUserAccount(
                accountID: usdcAccount.accountID,
                currency: usdcAccount.currency,
                createdAt: usdcAccount.createdAt,
                enriched: false,
                blockchainDepositAddress: nil,
                availableBalance: 0
            )
        }
        self.walletId = wallet.walletID
        self.accounts = UserAccounts(eur: eur, usdc: usdc)
    }
}

public struct UserAccounts: Codable {
    public var eur: EURUserAccount?
    public var usdc: USDCUserAccount?
}

public struct EURUserAccount: Codable {
    public let accountID: String
    public let currency: String
    public let createdAt: String
    public let enriched: Bool
    public let iban: String?
    public let bic: String?
    public let bankAccountHolderName: String?

    public init(accountID: String, currency: String, createdAt: String, enriched: Bool, iban: String? = nil, bic: String? = nil, bankAccountHolderName: String? = nil) {
        self.accountID = accountID
        self.currency = currency
        self.createdAt = createdAt
        self.enriched = enriched
        self.iban = iban
        self.bic = bic
        self.bankAccountHolderName = bankAccountHolderName
    }
}

public struct USDCUserAccount: Codable {
    public let accountID: String
    public let currency: String
    public let createdAt: String
    public let enriched: Bool
    public let blockchainDepositAddress: String?
    public var availableBalance: Int // Available balance in cents
}
