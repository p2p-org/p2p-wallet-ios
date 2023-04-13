//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.03.2023.
//

import BigInt
import Foundation

/// Helper protocol for quickly converting to ``CryptoAmount``.
public protocol CryptoAmountConvertible {
    var asCryptoAmount: CryptoAmount { get }
}

/// A string-formatter for crypto.
public class CryptoFormatter: Formatter {
    public let defaultValue: String
    public let prefix: String
    public let hideSymbol: Bool

    public init(defaultValue: String = "", prefix: String = "", hideSymbol: Bool = false) {
        self.defaultValue = defaultValue
        self.prefix = prefix
        self.hideSymbol = hideSymbol
        super.init()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError()
    }

    public func string(amount: CryptoAmountConvertible) -> String {
        formattedValue(for: amount.asCryptoAmount) ?? defaultValue
    }

    public func string(amount: CryptoAmount) -> String {
        formattedValue(for: amount) ?? defaultValue
    }

    override public func string(for obj: Any?) -> String? {
        formattedValue(for: obj)
    }

    public func string(for obj: Any?, maxDigits: Int? = nil) -> String? {
        formattedValue(for: obj, maxDigits: maxDigits)
    }

    // MARK: - Private

    private func formattedValue(for obj: Any?, maxDigits: Int? = nil) -> String? {
        let amount: CryptoAmount?

        if let obj = obj as? CryptoAmount {
            amount = obj
        } else if let obj = obj as? CryptoAmountConvertible {
            amount = obj.asCryptoAmount
        } else {
            amount = nil
        }

        guard let amount else { return nil }

        let formatter = NumberFormatter()
        formatter.groupingSize = 3
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = " "
        if let maxDigits {
            formatter.maximumFractionDigits = maxDigits
        } else {
            formatter.maximumFractionDigits = Int(amount.token.decimals)
        }

        let convertedValue = Decimal(string: String(amount.amount))
        guard var formattedAmount = formatter.string(for: convertedValue) else {
            return nil
        }

        if !prefix.isEmpty {
            formattedAmount = prefix + " \(formattedAmount)"
        }

        if hideSymbol {
            return formattedAmount
        } else {
            return "\(formattedAmount) \(amount.token.symbol)"
        }
    }
}
