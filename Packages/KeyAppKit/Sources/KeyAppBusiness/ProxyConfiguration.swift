//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.05.2023.
//

import Foundation

public struct ProxyConfiguration {
    public let address: String
    public let port: Int?

    public init(address: String, port: Int?) {
        self.address = address
        self.port = port
    }
}
