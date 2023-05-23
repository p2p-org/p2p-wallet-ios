//
//  AnyToken.swift
//
//
//  Created by Giang Long Tran on 24.03.2023.
//

import Foundation

/// Any token for easy converable
public protocol AnyToken {
    /// Token primary key
    var tokenPrimaryKey: String { get }

    /// Token symbol
    var symbol: String { get }

    /// Token full name
    var name: String { get }

    /// Decimal for token
    var decimals: UInt8 { get }

    var network: TokenNetwork { get }
}

public extension AnyToken {
    var asSomeToken: SomeToken {
        SomeToken(tokenPrimaryKey: tokenPrimaryKey, symbol: symbol, name: name, decimals: decimals, network: network)
    }
}

public enum TokenNetwork: Hashable, Codable {
    case solana
    case ethereum
}

public struct SomeToken: AnyToken, Hashable, Codable {
    public let tokenPrimaryKey: String

    public let symbol: String

    public let name: String

    public let decimals: UInt8

    public let network: TokenNetwork

    public init(
        tokenPrimaryKey: String,
        symbol: String,
        name: String,
        decimals: UInt8,
        network: TokenNetwork
    ) {
        self.tokenPrimaryKey = tokenPrimaryKey
        self.symbol = symbol
        self.name = name
        self.decimals = decimals
        self.network = network
    }
}
