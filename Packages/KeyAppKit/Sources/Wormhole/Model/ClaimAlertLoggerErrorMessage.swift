import Foundation

struct ClaimAlertError: Error {}

public struct ClaimAlertLoggerErrorMessage: Codable {
    var tokenToClaim: Token
    var userPubkey: String
    var userEthPubkey: String
    var platform: String
    var appVersion: String
    var timestamp: String
    var simulationError: String?
    var bridgeSeviceError: String?
    var feeRelayerError: String?
    var blockchainError: String?
}

extension ClaimAlertLoggerErrorMessage {
    struct Token: Codable {
        var name: String
        var solanaMint: String?
        var ethMint: String?
        var claimAmount: String?
    }
}
