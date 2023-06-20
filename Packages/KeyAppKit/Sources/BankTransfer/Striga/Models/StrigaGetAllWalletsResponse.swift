// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let strigaGetAllWalletResponse = try? JSONDecoder().decode(StrigaGetAllWalletsResponse.self, from: jsonData)

import Foundation

// MARK: - StrigaGetAllWalletsResponse

public struct StrigaGetAllWalletsResponse: Codable {
    public let wallets: [StrigaWallet]
    public let count, total: Int
    
    public init(wallets: [StrigaWallet], count: Int, total: Int) {
        self.wallets = wallets
        self.count = count
        self.total = total
    }
}

// MARK: - StrigaWallet

public struct StrigaWallet: Codable {
    public let walletID: String
    public let accounts: StrigaWalletAccounts
    
    enum CodingKeys: String, CodingKey {
        case walletID = "walletId"
        case accounts
    }
    
    public init(walletID: String, accounts: StrigaWalletAccounts) {
        self.walletID = walletID
        self.accounts = accounts
    }
}

// MARK: - StrigaWalletAccounts

public struct StrigaWalletAccounts: Codable {
    public let eur: StrigaWalletAccount?
    public let usdc: StrigaWalletAccount?
    public let syncedOwnerID, ownerType, createdAt, comment: String
    
    enum CodingKeys: String, CodingKey {
        case eur = "EUR"
        case usdc = "USDC"
        case syncedOwnerID = "syncedOwnerId"
        case ownerType, createdAt, comment
    }
    
    public init(eur: StrigaWalletAccount, usdc: StrigaWalletAccount, syncedOwnerID: String, ownerType: String, createdAt: String, comment: String) {
        self.eur = eur
        self.usdc = usdc
        self.syncedOwnerID = syncedOwnerID
        self.ownerType = ownerType
        self.createdAt = createdAt
        self.comment = comment
    }
}

// MARK: - StrigaWalletAccount

public struct StrigaWalletAccount: Codable {
    public let accountID, parentWalletID, currency, ownerID: String
    public let ownerType, createdAt: String
    public let availableBalance: StrigaWalletAccountAvailableBalance
    public let linkedCardID: String
    public let linkedBankAccountID: String?
    public let status: String
    public let permissions: [String]
    public let enriched: Bool
    public let blockchainDepositAddress: String?
    public let blockchainNetwork: StrigaWalletAccountBlockchainNetwork?
    
    enum CodingKeys: String, CodingKey {
        case accountID = "accountId"
        case parentWalletID = "parentWalletId"
        case currency
        case ownerID = "ownerId"
        case ownerType, createdAt, availableBalance
        case linkedCardID = "linkedCardId"
        case linkedBankAccountID = "linkedBankAccountId"
        case status, permissions, enriched, blockchainDepositAddress, blockchainNetwork
    }
    
    public init(accountID: String, parentWalletID: String, currency: String, ownerID: String, ownerType: String, createdAt: String, availableBalance: StrigaWalletAccountAvailableBalance, linkedCardID: String, linkedBankAccountID: String?, status: String, permissions: [String], enriched: Bool, blockchainDepositAddress: String?, blockchainNetwork: StrigaWalletAccountBlockchainNetwork?) {
        self.accountID = accountID
        self.parentWalletID = parentWalletID
        self.currency = currency
        self.ownerID = ownerID
        self.ownerType = ownerType
        self.createdAt = createdAt
        self.availableBalance = availableBalance
        self.linkedCardID = linkedCardID
        self.linkedBankAccountID = linkedBankAccountID
        self.status = status
        self.permissions = permissions
        self.enriched = enriched
        self.blockchainDepositAddress = blockchainDepositAddress
        self.blockchainNetwork = blockchainNetwork
    }
}

// MARK: - StrigaWalletAccountAvailableBalance

public struct StrigaWalletAccountAvailableBalance: Codable {
    public let amount, currency: String
    
    public init(amount: String, currency: String) {
        self.amount = amount
        self.currency = currency
    }
}

// MARK: - StrigaWalletAccountBlockchainNetwork

public struct StrigaWalletAccountBlockchainNetwork: Codable {
    public let name, type, contractAddress: String
    
    public init(name: String, type: String, contractAddress: String) {
        self.name = name
        self.type = type
        self.contractAddress = contractAddress
    }
}
