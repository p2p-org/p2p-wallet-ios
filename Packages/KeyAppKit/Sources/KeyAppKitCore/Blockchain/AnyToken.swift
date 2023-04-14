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

    var maxFractionDigit: UInt8 { get }
}

public extension AnyToken {
    var asSomeToken: SomeToken {
        SomeToken(tokenPrimaryKey: tokenPrimaryKey, symbol: symbol, name: name, decimals: decimals)
    }

    var maxFractionDigit: UInt8 { decimals }
}

public struct SomeToken: AnyToken, Hashable, Codable {
    public let tokenPrimaryKey: String

    public let symbol: String

    public let name: String

    public let decimals: UInt8

    /// Max displaying fraction digit
    public let maxFractionDigit: UInt8

    public init(
        tokenPrimaryKey: String,
        symbol: String,
        name: String,
        decimals: UInt8,
        maxFractionDigit: UInt8? = nil
    ) {
        self.tokenPrimaryKey = tokenPrimaryKey
        self.symbol = symbol
        self.name = name
        self.decimals = decimals
        self.maxFractionDigit = maxFractionDigit ?? decimals
    }
}
