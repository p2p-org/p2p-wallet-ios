import Foundation

public struct SendWormholeAlertLoggerErrorMessage: Codable {
    public let tokenToSend: Token
    public let arbiterFeeAmount, userPubkey, recipientEthPubkey: String
    public var platform: String = "iOS \(UIDevice.current.systemVersion)"
    public var appVersion: String = AppInfo.appVersionDetail
    public var timestamp: String = "\(Int64(Date().timeIntervalSince1970 * 1000))"
    public let simulationError: String?
    public let feeRelayerError: String?
    public let blockchainError: String?

    enum CodingKeys: String, CodingKey {
        case tokenToSend = "token_to_send"
        case arbiterFeeAmount = "arbiter_fee_amount"
        case userPubkey = "user_pubkey"
        case recipientEthPubkey = "recipient_eth_pubkey"
        case platform
        case appVersion = "app_version"
        case timestamp
        case simulationError = "simulation_error"
        case feeRelayerError = "fee_relayer_error"
        case blockchainError = "blockchain_error"
    }
}

public extension SendWormholeAlertLoggerErrorMessage {
    struct Token: Codable {
        public let name, mint, sendAmount: String

        enum CodingKeys: String, CodingKey {
            case name, mint
            case sendAmount = "send_amount"
        }
    }
}
