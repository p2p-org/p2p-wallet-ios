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

/// The class for formatting Key App currency
public class CurrencyFormatter: Formatter {
    public func string(amount: CurrencyAmount) -> String {
        string(for: amount) ?? "N/A"
    }

    override public func string(for obj: Any?) -> String? {
        guard let obj = obj as? CurrencyAmount else {
            return nil
        }

        let formatter = NumberFormatter()

        // Set currency mode
        formatter.currencyCode = obj.currencyCode
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en-US")

        // Fix prefix padding
        // formatter.negativePrefix = "\(formatter.negativePrefix!) "
        // formatter.positivePrefix = "\(formatter.positivePrefix!) "

        // Set style
        formatter.groupingSize = 3
        formatter.currencyDecimalSeparator = "."
        formatter.currencyGroupingSeparator = " "

        let value: String? = formatter.string(for: obj.value)
        return value
    }
}
