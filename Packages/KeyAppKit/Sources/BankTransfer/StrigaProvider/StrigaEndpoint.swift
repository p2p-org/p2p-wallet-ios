//
//  Endpoints.swift
//  p2p_wallet
//
//  Created by Ivan on 15.05.2023.
//

import Foundation
import KeyAppNetworking

enum StrigaEndpoint {
    case verifyMobileNumber(authHeader: AuthHeader, userId: String, verificationCode: String)
    case createUser(authHeader: AuthHeader, model: CreateUserRequest)
}

// MARK: - HTTPEndpoint

extension StrigaEndpoint: HTTPEndpoint {
    var baseURL: String {
        "https://\(urlEnvironment)/api/\(version)/user/"
    }
    
    var header: [String: String] {
        [
            "Content-Type": "application/json",
            "User-PublicKey": authHeader.pubKey,
            "Signed-Message": authHeader.signedMessage
        ]
    }
    
    var path: String {
        switch self {
        case .verifyMobileNumber:
            return "verify-mobile"
        case .createUser:
            return "create"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .verifyMobileNumber, .createUser:
            return .post
        }
    }

    var body: String? {
        switch self {
        case let .verifyMobileNumber(_, userId, verificationCode):
            return ["userId": userId, "verificationCode": verificationCode].encoded
        case let .createUser(_, model):
            return model.encoded
        }
    }
}

// MARK: - URL parts

private extension StrigaEndpoint {
    var urlEnvironment: String {
        switch self {
        case .verifyMobileNumber, .createUser:
            return "payment.keyapp.org/striga"
        }
    }
    
    var version: String {
        "v1"
    }
    
    var authHeader: AuthHeader {
        switch self {
        case let .verifyMobileNumber(authHeader, _, _):
            return authHeader
        case let .createUser(authHeader, _):
            return authHeader
        }
    }
}

// MARK: - Encoding

private extension Encodable {
    /// Encoded string for request as a json string
    var encoded: String? {
        encoded(strategy: .useDefaultKeys)
    }
    
    func encoded(strategy: JSONEncoder.KeyEncodingStrategy) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.keyEncodingStrategy = strategy
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Auth Header

extension StrigaEndpoint {
    struct AuthHeader {
        let pubKey: String
        let signedMessage: String
    }
}
