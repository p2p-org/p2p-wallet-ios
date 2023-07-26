public struct UserWallet: Codable {
    public let walletId: String
    public var accounts: UserAccounts
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
    public let availableBalance: Int?

    public init(
        accountID: String,
        currency: String,
        createdAt: String,
        enriched: Bool,
        availableBalance: Int?,
        iban: String? = nil,
        bic: String? = nil,
        bankAccountHolderName: String? = nil
    ) {
        self.accountID = accountID
        self.currency = currency
        self.createdAt = createdAt
        self.enriched = enriched
        self.availableBalance = availableBalance
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
    public var availableBalance: Int // Available balance in cents with fee
    public var totalBalance: Int // Total balnce without Fee

    mutating func setAvailableBalance(_ amount: Int) {
        self.availableBalance = amount
    }
}
