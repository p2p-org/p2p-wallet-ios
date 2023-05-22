import Foundation
import Resolver
import SolanaSwift
import FeeRelayerSwift

enum AlertLoggerDataBuilder {
    struct AlertLoggerData {
        let platform: String
        let userPubkey: String
        let blockchainError: String?
        let feeRelayerError: String?
        let appVersion: String
        let timestamp: String
    }
    
    static func buildLoggerData(
        error: Error
    ) async -> AlertLoggerData {
        let platform = "iOS \(await UIDevice.current.systemVersion)"
        let userPubkey = Resolver.resolve(UserWalletManager.self).wallet?.account.publicKey.base58EncodedString ?? ""
        
        var blockchainError: String?
        var feeRelayerError: String?
        switch error {
        case let error as APIClientError:
            blockchainError = error.blockchainErrorDescription
        case let error as FeeRelayerError where error.message == "Topping up is successfull, but the transaction failed":
            feeRelayerError = APIClientError.responseError(
                .init(
                    code: error.code,
                    message: error.message,
                    data: .init(logs: error.data?.data?.array)
                )
            )
                .blockchainErrorDescription
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
