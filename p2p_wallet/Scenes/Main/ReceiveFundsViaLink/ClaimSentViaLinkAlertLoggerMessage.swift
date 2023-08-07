import Foundation

// MARK: - ClaimSentViaLinkAlertLoggerMessage

struct ClaimSentViaLinkAlertLoggerMessage: Codable {
    let tokenToClaim: ClaimSentViaLinkAlertLoggerTokenToClaim
    let userPubkey, platform, appVersion, timestamp: String
    let simulationError, feeRelayerError, blockchainError: String?

    enum CodingKeys: String, CodingKey {
        case tokenToClaim = "token_to_claim"
        case userPubkey = "user_pubkey"
        case platform
        case appVersion = "app_version"
        case timestamp
        case simulationError = "simulation_error"
        case feeRelayerError = "fee_relayer_error"
        case blockchainError = "blockchain_error"
    }
}

// MARK: - ClaimSentViaLinkAlertLoggerTokenToClaim

struct ClaimSentViaLinkAlertLoggerTokenToClaim: Codable {
    let name, mint, claimAmount, currency: String

    enum CodingKeys: String, CodingKey {
        case name, mint
        case claimAmount = "claim_amount"
        case currency
    }
}
