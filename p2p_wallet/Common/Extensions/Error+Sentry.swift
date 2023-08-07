import FeeRelayerSwift
import Foundation
import SolanaSwift

extension FeeRelayerSwift.FeeRelayerError: CustomNSError {
    public var errorUserInfo: [String: Any] {
        struct LoggingError: Encodable {
            let code: Int
            let message: String
        }
        return [NSDebugDescriptionErrorKey: LoggingError(code: code, message: message)
            .jsonString ?? "\(code), \(message)"]
    }
}

extension SolanaSwift.APIClientError: CustomNSError {
    public var errorUserInfo: [String: Any] {
        func getDebugDescription() -> String {
            switch self {
            case .invalidAPIURL:
                return "Invalid APIURL"
            case .invalidResponse:
                return "Invalid response"
            case let .responseError(response):
                return response.jsonString ?? response.message ?? "\(response)"
            case let .transactionSimulationError(logs: logs):
                return "Transaction simulation failed: \(logs.jsonString ?? "")"
            case .couldNotRetrieveAccountInfo:
                return "Could not retrive account info"
            case .blockhashNotFound:
                return "Blockhash not found"
            }
        }

        return [NSDebugDescriptionErrorKey: getDebugDescription()]
    }
}
