//
//  Error+Sentry.swift
//  p2p_wallet
//
//  Created by Chung Tran on 20/04/2023.
//

import Foundation
import SolanaSwift
import FeeRelayerSwift

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
                return response.message ?? "\(response)"
            }
        }
        
        return [NSDebugDescriptionErrorKey: getDebugDescription()]
    }
}


