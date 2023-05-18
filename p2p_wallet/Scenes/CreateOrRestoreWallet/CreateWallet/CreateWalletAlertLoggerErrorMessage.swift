import Foundation

public struct CreateWalletAlertLoggerErrorMessage: Codable {
    let error: String

    enum CodingKeys: String, CodingKey {
        case error = "web3_error"
    }
}

