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
    public let defaultValue: String
    public let hideSymbol: Bool
    public let lessText: String

    public init(defaultValue: String = "", hideSymbol: Bool = false, lessText: String = "Less than") {
        self.defaultValue = defaultValue
        self.hideSymbol = hideSymbol
        self.lessText = lessText
        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func string(amount: CurrencyAmount) -> String {
        string(for: amount) ?? defaultValue
    }

    public func string(amount: CurrencyConvertible) -> String {
        string(for: amount) ?? defaultValue
    }

    override public func string(for obj: Any?) -> String? {
        formattedValue(for: obj) ?? defaultValue
    }

    private func formattedValue(for obj: Any?) -> String? {
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

        // Set currency mode
        formatter.currencyCode = amount.currencyCode
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en-US")

        if hideSymbol {
            formatter.currencySymbol = ""
        }

        // Set style
        formatter.groupingSize = 3
        formatter.currencyDecimalSeparator = "."
        formatter.currencyGroupingSeparator = " "
        formatter.maximumFractionDigits = 2

        let decimalAmount = Decimal(string: String(amount.value))
        let value: String? = formatter.string(for: decimalAmount)

        guard var value else {
            return value
        }

        if !lessText.isEmpty, amount.value > 0.0, amount.value < 0.01 {
            value = "\(lessText) \(value)"
        }

        return value
    }
}
