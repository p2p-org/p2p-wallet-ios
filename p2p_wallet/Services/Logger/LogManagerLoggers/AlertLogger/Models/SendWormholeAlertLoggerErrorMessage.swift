import Foundation

struct SendWormholeAlertLoggerErrorMessage: Codable {
    let tokenToSend: Token
    let arbiterFeeAmount, userPubkey, recipientEthPubkey: String
    var platform: String = "iOS \(UIDevice.current.systemVersion)"
    var appVersion: String = AppInfo.appVersionDetail
    var timestamp: String = "\(Int64(Date().timeIntervalSince1970 * 1000))"
    let simulationError: String?
    let feeRelayerError: String?
    let blockchainError: String?

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

extension SendWormholeAlertLoggerErrorMessage {
    struct Token: Codable {
        let name, mint, sendAmount: String

        enum CodingKeys: String, CodingKey {
            case name, mint
            case sendAmount = "send_amount"
        }
    }
}
