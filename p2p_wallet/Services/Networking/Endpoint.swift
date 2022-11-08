//
//  Endpoint.swift
//  p2p_wallet
//
//  Created by Ivan on 28.04.2022.
//

import Foundation

protocol Endpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: RequestMethod { get }
    var header: [String: String] { get }
    var body: String? { get }
}

extension Endpoint {
    var header: [String: String] {
        [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "CHANNEL_ID": "P2PWALLET_MOBILE",
        ]
    }

    var baseURL: String {
        #if !RELEASE
            return "http://35.234.120.240:9090/"
        #else
            return "https://push-service.wallet.p2p.org/"
        #endif
    }
}
