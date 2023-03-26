//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.03.2023.
//

import BigDecimal
import Foundation

// A structure for handling token price
public struct TokenPrice: Hashable {
    /// ISO 4217 Currency code
    public let currencyCode: String

    /// Value of price
    public let value: BigDecimal?

    public let symbol: String

    public let decimals: UInt8

    public let smartContract: String

    @available(*, deprecated, message: "Never use double for fiat.")
    public var doubleValue: Double {
        guard let value else { return 0.0 }
        return Double(value.description) ?? 0.0
    }

    public init(currencyCode: String, value: BigDecimal?, token: AnyToken) {
        self.currencyCode = currencyCode
        self.value = value

        symbol = token.symbol
        decimals = token.decimals
        smartContract = token.tokenPrimaryKey
    }

    public init(currencyCode: String, value: Decimal?, token: AnyToken) {
        let normalizedValue = NSDecimalNumber(decimal: value ?? 0.0)
        let convertedValue: BigDecimal = (try? BigDecimal(fromString: normalizedValue.stringValue)) ?? 0.0

        self.init(currencyCode: currencyCode, value: convertedValue, token: token)
    }
}
