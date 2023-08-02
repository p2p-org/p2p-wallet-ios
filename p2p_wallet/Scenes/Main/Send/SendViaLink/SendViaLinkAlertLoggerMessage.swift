import Foundation

// MARK: - SendViaLinkAlertLoggerMessage

struct SendViaLinkAlertLoggerMessage: Codable {
    let tokenToSend: SendViaLinkAlertLoggerTokenToSend
    let userPubkey, platform, appVersion, timestamp: String
    let simulationError, feeRelayerError, blockchainError: String?

    enum CodingKeys: String, CodingKey {
        case tokenToSend = "token_to_send"
        case userPubkey = "user_pubkey"
        case platform
        case appVersion = "app_version"
        case timestamp
        case simulationError = "simulation_error"
        case feeRelayerError = "fee_relayer_error"
        case blockchainError = "blockchain_error"
    }
}

// MARK: - SendViaLinkAlertLoggerTokenToSend

struct SendViaLinkAlertLoggerTokenToSend: Codable {
    let name, mint, sendAmount, currency: String

    enum CodingKeys: String, CodingKey {
        case name, mint
        case sendAmount = "send_amount"
        case currency
    }
}
