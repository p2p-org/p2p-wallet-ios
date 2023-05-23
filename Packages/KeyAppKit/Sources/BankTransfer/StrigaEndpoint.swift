//
//  Endpoints.swift
//  p2p_wallet
//
//  Created by Ivan on 15.05.2023.
//

import Foundation
import KeyAppNetworking

enum StrigaEndpoint {
    case verifyMobileNumber(userId: String, verificationCode: String)
}

// MARK: - HTTPEndpoint

extension StrigaEndpoint: HTTPEndpoint {
    var baseURL: String {
        "https://\(urlEnvironment)/api/\(version)/user/"
    }
    
    private var urlEnvironment: String {
        switch self {
        case .verifyMobileNumber:
            return "payment.keyapp.org/striga"
        }
    }
    
    private var version: String {
        "v1"
    }
    
    var header: [String: String] {
        [
            "Content-Type": "application/json",
            "User-id": ""
        ]
    }
    
    var path: String {
        switch self {
        case .verifyMobileNumber:
            return "verify-mobile"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .verifyMobileNumber:
            return .post
        }
    }

    var body: String? {
        switch self {
        case let .verifyMobileNumber(userId, verificationCode):
            return nil
//            return ["userId": userId, "verificationCode": verificationCode].encoded
        }
    }
}

private extension Encodable {
    /// Encoded string for request as a json string
    var encoded: String? {
        encoded(strategy: .useDefaultKeys)
    }
    
    private func encoded(strategy: JSONEncoder.KeyEncodingStrategy) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.keyEncodingStrategy = strategy
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
