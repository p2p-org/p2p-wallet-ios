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

extension SolanaSDK.Error {
    public var errorDescription: String? {
        switch self {
        case .accountNotFound:
            return L10n.accountNotFound
        case .publicKeyNotFound:
            return L10n.publicKeyNotFound
        case .invalidURL:
            return L10n.invalidURL
        case .invalidStatusCode(code: let code):
            return L10n.invalidStatusCode + " \(code)"
        case .responseError(let error):
            return (error as? LocalizedError)?.localizedDescription
        case .other(let string):
            return string
        case .socket(let error):
            return (error as? LocalizedError)?.localizedDescription
        case .unknown:
            return L10n.unknownError
        }
    }
}
