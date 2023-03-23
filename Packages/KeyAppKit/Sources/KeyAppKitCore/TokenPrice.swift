//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.03.2023.
//

import Foundation

public struct TokenPrice: Hashable, CustomStringConvertible {
    /// ISO 4217 Currency code
    public let currencyCode: String

    /// Value of price
    public let value: Decimal?

    public let symbol: String

    public let decimals: UInt8

    public let smartContract: String
    
    @available(*, deprecated, message: "Never use double for fiat.")
    public var doubleValue: Double {
        guard let value else { return 0.0 }
        return NSDecimalNumber(decimal: value).doubleValue
    }

    public init(currencyCode: String, value: Decimal?, token: AnyToken) {
        self.currencyCode = currencyCode
        self.value = value

        self.symbol = token.symbol
        self.decimals = token.decimals
        self.smartContract = token.tokenPrimaryKey
    }
    
    public var description: String {
        return "Nothing"
    }
}
