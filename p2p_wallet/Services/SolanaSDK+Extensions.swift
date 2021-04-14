//
//  SolanaSDK+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import RxSwift

extension SolanaSDK.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return L10n.unauthorized
        case .notFound:
            return L10n.notFound
        case .invalidRequest(let reason):
            var message = L10n.invalidRequest
            if let reason = reason {
                message = reason.localized()
            }
            return message
        case .invalidResponse(let responseError):
            var string = L10n.responseError
            if let description = responseError.message {
                string = description.localized()
            }
            return string
        case .socket(let error):
            var string = L10n.socketReturnsAnError + ": "
            if let error = error as? LocalizedError {
                string += error.errorDescription ?? error.localizedDescription
            } else {
                string += error.localizedDescription
            }
            return string
        case .other(let string):
            return string.localized()
        case .unknown:
            return L10n.unknownError
        }
    }
}
