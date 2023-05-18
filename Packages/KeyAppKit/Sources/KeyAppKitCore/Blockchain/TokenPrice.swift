//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.03.2023.
//

import BigDecimal
import Foundation

// A structure for handling token price
public struct TokenPrice: Hashable, Codable {
    /// ISO 4217 Currency code
    public let currencyCode: String

    /// Token that keep the price
    public let token: SomeToken

    /// Value of price
    public let value: BigDecimal

    @available(*, deprecated, message: "Never use double for store fiat.")
    public var doubleValue: Double {
        Double(value.description) ?? 0.0
    }

    public init(currencyCode: String, value: BigDecimal, token: AnyToken) {
        self.currencyCode = currencyCode
        self.value = value
        self.token = token.asSomeToken
    }

    public init(currencyCode: String, value: Decimal?, token: AnyToken) {
        let normalizedValue = NSDecimalNumber(decimal: value ?? 0.0)
        let convertedValue: BigDecimal = (try? BigDecimal(fromString: normalizedValue.stringValue)) ?? 0.0

        self.init(currencyCode: currencyCode, value: convertedValue, token: token)
    }
}
