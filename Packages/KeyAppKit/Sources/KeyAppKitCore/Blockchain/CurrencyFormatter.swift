//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.03.2023.
//

import Foundation

/// Helper protocol for quickly converting to ``CurrencyAmount``.
public protocol CurrencyConvertible {
    var asCurrencyAmount: CurrencyAmount { get }
}

/// The class for formatting currency.
public class CurrencyFormatter: Formatter {
    public func string(amount: CurrencyAmount, defaultValue: String = "N/A", withCode: Bool = true) -> String {
        (withCode ? string(for: amount) : stringValue(for: amount)) ?? defaultValue
    }

    public func string(amount: CurrencyConvertible, defaultValue: String = "N/A") -> String {
        string(for: amount) ?? defaultValue
    }

    override public func string(for obj: Any?) -> String? {
        return formattedValue(for: obj, withSymbol: true)
    }

    private func stringValue(for obj: Any?) -> String? {
        return formattedValue(for: obj, withSymbol: false)
    }

    private func formattedValue(for obj: Any?, withSymbol: Bool) -> String? {
        let amount: CurrencyAmount?

        if let obj = obj as? CurrencyConvertible {
            amount = obj.asCurrencyAmount
        } else if let obj = obj as? CurrencyAmount {
            amount = obj
        } else {
            amount = nil
        }

        guard let amount else { return nil }

        let formatter = NumberFormatter()
        formatter.roundingMode = .down

        if withSymbol {
            // Set currency mode
            formatter.currencyCode = amount.currencyCode
            formatter.numberStyle = .currency
            formatter.locale = Locale(identifier: "en-US")
        }

        // Fix prefix padding
        // formatter.negativePrefix = "\(formatter.negativePrefix!) "
        // formatter.positivePrefix = "\(formatter.positivePrefix!) "

        // Set style
        formatter.groupingSize = 3
        formatter.currencyDecimalSeparator = "."
        formatter.currencyGroupingSeparator = " "
        formatter.maximumFractionDigits = 2

        let decimalAmount = Decimal(string: String(amount.value))
        let value: String? = formatter.string(for: decimalAmount)
        return value
    }
}
