import Foundation
import Resolver
import SolanaSwift

enum AlertLoggerDataBuilder {
    struct AlertLoggerDataBuilder {
        let platform: String
        let userPubkey: String
        let blockchainError: String?
        let feeRelayerError: String?
        let appVersion: String
        let timestamp: String
    }
    
    static func buildLoggerData(
        error: Error
    ) async -> AlertLoggerDataBuilder {
        let platform = "iOS \(await UIDevice.current.systemVersion)"
        let userPubkey = Resolver.resolve(UserWalletManager.self).wallet?.account.publicKey.base58EncodedString ?? ""
        
        var blockchainError: String?
        var feeRelayerError: String?
        switch error {
        case let error as APIClientError:
            blockchainError = error.blockchainErrorDescription
        default:
            feeRelayerError = "\(error)"
        }
        
        let appVersion = AppInfo.appVersionDetail
        let timestamp = "\(Int64(Date().timeIntervalSince1970 * 1000))"
        
        return .init(
            platform: platform,
            userPubkey: userPubkey,
            blockchainError: blockchainError,
            feeRelayerError: feeRelayerError,
            appVersion: appVersion,
            timestamp: timestamp
        )
    }
}

private extension APIClientError {
    var blockchainErrorDescription: String {
        switch self {
        case .cantEncodeParams:
            return "cantEncodeParams"
        case .invalidAPIURL:
            return "invalidAPIURL"
        case .invalidResponse:
            return "emptyResponse"
        case .responseError(let responseError):
            guard let data = try? JSONEncoder().encode(responseError),
                  let string = String(data: data, encoding: .utf8)
            else {
                return "unknownResponseError"
            }
            return string
        }
    }
}
