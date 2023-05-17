import Foundation
import SolanaSwift

extension APIClientError {
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
