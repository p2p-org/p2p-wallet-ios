import Foundation

struct ClaimAlertLoggerErrorMessage: Codable {
    var tokenToClaim: Token
    var userPubkey: String
    var userEthPubkey: String
    var platform: String = "iOS \(UIDevice.current.systemVersion)"
    var appVersion: String = AppInfo.appVersionDetail
    var timestamp: String = "\(Int64(Date().timeIntervalSince1970 * 1000))"
    var simulationError: String?
    var bridgeSeviceError: String?
    var feeRelayerError: String?
    var blockchainError: String?

    enum CodingKeys: String, CodingKey {
        case tokenToClaim = "token_to_claim"
        case userPubkey = "user_pubkey"
        case userEthPubkey = "user_eth_pubkey"
        case platform
        case appVersion = "app_version"
        case timestamp
        case simulationError = "simulation_error"
        case bridgeSeviceError = "bridge_sevice_error"
        case feeRelayerError = "fee_relayer_error"
        case blockchainError = "blockchain_error"
    }
}

extension ClaimAlertLoggerErrorMessage {
    // MARK: - Token
    struct Token: Codable {
        let name, solanaMint, ethMint: String
        let claimAmount: String

        enum CodingKeys: String, CodingKey {
            case name
            case solanaMint = "solana_mint"
            case ethMint = "eth_mint"
            case claimAmount = "claim_amount"
        }
    }
}
