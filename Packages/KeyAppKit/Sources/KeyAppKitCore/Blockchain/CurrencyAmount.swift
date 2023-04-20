//
//  File.swift
//
//
//  Created by Giang Long Tran on 24.03.2023.
//

import BigDecimal
import BigInt
import Foundation

/// Amount in fiat struct
public struct CurrencyAmount: Hashable, Codable, Equatable {
    /// Value
    public let value: BigDecimal

    /// ISO 4217 Currency code
    public let currencyCode: String

    /// Initialise amount in specific ``currencyCode``
    public init(value: BigDecimal, currencyCode: String) {
        self.value = value
        self.currencyCode = currencyCode.uppercased()
    }

    /// USD amount
    public init(usd: BigDecimal) {
        value = usd
        currencyCode = "USD"
    }

    /// USD amount
    public init(usdStr: String) {
        value = (try? BigDecimal(fromString: usdStr)) ?? 0.0
        currencyCode = "USD"
    }

    /// Zero value in usd
    public static var zero: Self = .init(usd: 0)

    public func toCryptoAmount(price: TokenPrice) -> CryptoAmount? {
        let priceValue = price.value

        guard priceValue > 0 else {
            return nil
        }

        let decimalValue: BigDecimal = value / priceValue
        return CryptoAmount(floatString: String(decimalValue), token: price.token)
    }

    public func with(amount: BigDecimal) -> Self {
        .init(value: amount, currencyCode: currencyCode)
    }
}

public extension CurrencyAmount {
    /// Additional operation. Return left side if their ``currencyCode`` is different
    static func + (lhs: Self, rhs: Self) -> Self {
        guard lhs.currencyCode == rhs.currencyCode else {
            return lhs
        }

        return .init(value: lhs.value + rhs.value, currencyCode: lhs.currencyCode)
    }

    /// Additonal operation. Return left side if their ``currencyCode`` is different
    static func + (lhs: Self, rhs: Self?) -> Self {
        guard let rhs else { return lhs }
        return lhs + rhs
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        guard lhs.currencyCode == rhs.currencyCode else {
            return lhs
        }

        return .init(value: lhs.value - rhs.value, currencyCode: lhs.currencyCode)
    }
}

extension CurrencyAmount: Comparable {
    /// Compare currency amount. The currency should be same, otherweise it will return false.
    public static func < (lhs: CurrencyAmount, rhs: CurrencyAmount) -> Bool {
        // We not allow to compare two currency
        guard lhs.currencyCode == rhs.currencyCode else {
            return false
        }

        return lhs.value < rhs.value
    }

    public static func == (lhs: CurrencyAmount, rhs: CurrencyAmount) -> Bool {
        // We not allow to compare two currency
        guard lhs.currencyCode == rhs.currencyCode else {
            return false
        }

        return lhs.value == rhs.value
    }
}
