//
//  SolanaSDK+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import RxSwift

extension SolanaSDK {
    static var shared = SolanaSDK(network: Defaults.network, accountStorage: AccountStorage.shared)
}

extension String: ListItemType {
    static func placeholder(at index: Int) -> String {
        "\(index)"
    }
    var id: String {self}
}

extension SolanaSDK.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return L10n.unauthorized
        case .notFound:
            return L10n.notFound
        case .invalidRequest(let reason):
            return L10n.invalidRequest + ". " + L10n.reason + ": " + reason.localized()
        case .invalidResponse(let responseError):
            var string = L10n.responseError
            if let description = responseError.message {
                string += ": " + description.localized()
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
