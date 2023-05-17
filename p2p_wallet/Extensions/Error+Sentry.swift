//
//  Error+Sentry.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/04/2023.
//

import Foundation
import SolanaSwift
import FeeRelayerSwift

struct SentryUndefinedError: Error, CustomNSError {
    let error: Swift.Error
    public var errorUserInfo: [String : Any] {
        let message = "\(String(reflecting: error))"
        return [NSDebugDescriptionErrorKey: message ]
    }
}

extension FeeRelayerSwift.FeeRelayerError: CustomNSError {
    public var errorUserInfo: [String : Any] {
        struct LoggingError: Encodable {
            let code: Int
            let message: String
        }
        return [NSDebugDescriptionErrorKey: LoggingError(code: code, message: message).jsonString ?? "\(code), \(message)" ]
    }
}

extension SolanaSwift.APIClientError: CustomNSError {
    public var errorUserInfo: [String : Any] {
        func getDebugDescription() -> String {
            switch self {
            case .cantEncodeParams:
                return "Can not decode params"
            case .invalidAPIURL:
                return "Invalid APIURL"
            case .invalidResponse:
                return "Invalid response"
            case .responseError(let response):
                return response.jsonString ?? response.message ?? "\(response)"
            }
        }
        
        return [NSDebugDescriptionErrorKey: getDebugDescription()]
    }
}

extension SolanaError: CustomNSError {
    public var errorUserInfo: [String : Any] {
        func getDebugDescription() -> String {
            switch self {
            case .unauthorized:
                return "unauthorized"
            case .notFound:
                return "notFound"
            case .assertionFailed(let message):
                return message ?? "\(self)"
            case .invalidRequest(reason: let reason):
                return reason ?? "\(self)"
            case .transactionError(_, logs: let logs):
                return logs.jsonString ?? "\(self)"
            case .socket(_):
                return "\(self)"
            case .transactionHasNotBeenConfirmed:
                return "\(self)"
            case .other(let message):
                return message
            case .unknown:
                return "\(self)"
            }
        }
        
        return [NSDebugDescriptionErrorKey: getDebugDescription()]
    }
}
