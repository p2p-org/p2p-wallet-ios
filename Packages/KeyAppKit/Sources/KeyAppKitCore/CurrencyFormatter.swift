//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.03.2023.
//

import Foundation

/// Amount in fiat struct
public struct CurrencyAmount: Hashable {
    public let value: Decimal
    public let currencyCode: String

    public init(value: Decimal, currencyCode: String) {
        self.value = value
        self.currencyCode = currencyCode
    }

    public init(usd: Decimal) {
        self.value = usd
        self.currencyCode = "USD"
    }

    public static var zero: Self = .init(usd: 0)
}

public extension CurrencyAmount {
    static func + (lhs: Self, rhs: Self) -> Self {
        guard lhs.currencyCode == rhs.currencyCode else {
            return lhs
        }

        return .init(value: lhs.value + rhs.value, currencyCode: lhs.currencyCode)
    }

    static func + (lhs: Self, rhs: Self?) -> Self {
        guard let rhs else { return lhs }
        return lhs + rhs
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

public protocol CurrentyConverable {
    var asCurrencyAmount: CurrencyAmount { get }
}

/// The class for formatting Key App currency
public class CurrencyFormatter: Formatter {
    public func string(amount: CurrencyAmount) -> String {
        string(for: amount) ?? "N/A"
    }

    public func string(amount: CurrentyConverable) -> String {
        string(for: amount) ?? "N/A"
    }

    override public func string(for obj: Any?) -> String? {
        let amount: CurrencyAmount?

        if let obj = obj as? CurrentyConverable {
            amount = obj.asCurrencyAmount
        } else if let obj = obj as? CurrencyAmount {
            amount = obj
        } else {
            amount = nil
        }

        guard let amount else { return nil }

        let formatter = NumberFormatter()

        // Set currency mode
        formatter.currencyCode = amount.currencyCode
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en-US")

        // Fix prefix padding
        // formatter.negativePrefix = "\(formatter.negativePrefix!) "
        // formatter.positivePrefix = "\(formatter.positivePrefix!) "

        // Set style
        formatter.groupingSize = 3
        formatter.currencyDecimalSeparator = "."
        formatter.currencyGroupingSeparator = " "

        let value: String? = formatter.string(for: amount.value)
        return value
    }
}
