// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let strigaGetAllWalletResponse = try? JSONDecoder().decode(StrigaGetAllWalletsResponse.self, from: jsonData)

import Foundation

// MARK: - StrigaGetAllWalletsResponse

public struct StrigaGetAllWalletsResponse: Codable {
    public let wallets: [StrigaWallet]
    public let count, total: Int
}

// MARK: - StrigaWallet

public struct StrigaWallet: Codable {
    public let walletID: String
    public let accounts: StrigaWalletAccounts
    public let syncedOwnerID, ownerType, createdAt, comment: String

    enum CodingKeys: String, CodingKey {
        case walletID = "walletId"
        case accounts
        case syncedOwnerID = "syncedOwnerId"
        case ownerType, createdAt, comment
    }
}

// MARK: - StrigaWalletAccounts

public struct StrigaWalletAccounts: Codable {
    public let eur: StrigaWalletAccount?
    public let usdc: StrigaWalletAccount?

    enum CodingKeys: String, CodingKey {
        case eur = "EUR"
        case usdc = "USDC"
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
}

// MARK: - StrigaWalletAccountAvailableBalance

public struct StrigaWalletAccountAvailableBalance: Codable {
    public let amount, currency: String
}

// MARK: - StrigaWalletAccountBlockchainNetwork

public struct StrigaWalletAccountBlockchainNetwork: Codable {
    public let name, type, contractAddress: String
}
