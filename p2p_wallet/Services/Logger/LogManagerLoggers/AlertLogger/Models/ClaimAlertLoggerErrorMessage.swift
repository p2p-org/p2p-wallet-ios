import Foundation

public struct ClaimAlertLoggerErrorMessage: Codable {
    public var tokenToClaim: Token
    public var userPubkey: String
    public var userEthPubkey: String
    public var platform: String = "iOS \(UIDevice.current.systemVersion)"
    public var appVersion: String = AppInfo.appVersionDetail
    public var timestamp: String = "\(Int64(Date().timeIntervalSince1970 * 1000))"
    public var simulationError: String?
    public var bridgeSeviceError: String?
    public var feeRelayerError: String?
    public var blockchainError: String?

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

public extension ClaimAlertLoggerErrorMessage {
    // MARK: - Token
    struct Token: Codable {
        public let name, solanaMint, ethMint: String
        public let claimAmount: String

        enum CodingKeys: String, CodingKey {
            case name
            case solanaMint = "solana_mint"
            case ethMint = "eth_mint"
            case claimAmount = "claim_amount"
        }
    }
}
