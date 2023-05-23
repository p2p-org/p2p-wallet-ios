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

// MARK: - Endpoint

extension StrigaEndpoint: Endpoint {
    var baseURL: String {
        "https://\(urlEnvironment).striga.com/\(server)/api/\(version)/user/"
    }
    
    private var urlEnvironment: String {
        switch self {
        case .verifyMobileNumber:
            return "www.sandbox"
        }
    }
    
    private var server: String {
        switch self {
        case .verifyMobileNumber:
            return "server"
        }
    }
    
    private var version: String {
        "v0"
    }
    
    var header: [String: String] {
        [
            "api-key": "",
            "Authorization": "",
        ]
    }
    
    var path: String {
        switch self {
        case .verifyMobileNumber:
            return "verify-mobile"
        }
    }

    var method: RequestMethod {
        switch self {
        case .verifyMobileNumber:
            return .post
        }
    }

    var body: String? {
        switch self {
        case let .verifyMobileNumber(userId, verificationCode):
            return ["userId": userId, "verificationCode": verificationCode].encoded
        }
    }
}
