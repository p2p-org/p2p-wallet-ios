import Foundation

final class AlertLogger: LogManagerLogger {
    var supportedLogLevels: [LogLevel] = [.alert]

    private let url = URL(string: .secretConfig("SWAP_ERROR_LOGGER_ENDPOINT")!)!

    func log(event: String, logLevel: LogLevel, data: String?) {
        Task {
            // send request to endpoint
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = AlertLoggerError(title: event, message: data ?? "")
            urlRequest.httpBody = try JSONEncoder().encode(body)
            _ = try? await URLSession.shared.data(from: urlRequest)
        }
    }

}

// MARK: - Models

private struct AlertLoggerError: Error, Codable {
    var title: String
    var message: String
}

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

// MARK: - SendError

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
