//
//  Endpoint.swift
//  p2p_wallet
//
//  Created by Ivan on 28.04.2022.
//

import Foundation

public protocol HTTPEndpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var header: [String: String] { get }
    var body: String? { get }
}
