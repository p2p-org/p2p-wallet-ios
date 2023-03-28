//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.03.2023.
//

import BigInt
import Foundation

/// Helper protocol for quickly converting to ``CryptoAmount``.
public protocol CryptoAmountConverable {
    var asCryptoAmount: CryptoAmount { get }
}

/// A string-formatter for crypto.
public class CryptoFormatter: Formatter {
    let prefix: String

    public init(prefix: String = "") {
        self.prefix = prefix
        super.init()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError()
    }

    public func string(amount: CryptoAmountConverable) -> String {
        string(for: amount.asCryptoAmount) ?? "N/A"
    }

    public func string(amount: CryptoAmount, withCode: Bool = true) -> String {
        (withCode ? string(for: amount) : stringValue(for: amount)) ?? "N/A"
    }

    override public func string(for obj: Any?) -> String? {
        return formattedValue(for: obj, withSymbol: true)
    }

    // MARK: - Private

    private func stringValue(for obj: Any?) -> String? {
        return formattedValue(for: obj, withSymbol: false)
    }

    private func formattedValue(for obj: Any?, withSymbol: Bool) -> String? {
        let amount: CryptoAmount?

        if let obj = obj as? CryptoAmount {
            amount = obj
        } else if let obj = obj as? CryptoAmountConverable {
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
        formatter.maximumFractionDigits = Int(amount.decimals)

        let convertedValue = Decimal(string: String(amount.amount))
        guard var formattedAmount = formatter.string(for: convertedValue) else {
            return nil
        }

        if !prefix.isEmpty {
            formattedAmount = prefix + " \(formattedAmount)"
        }

        if withSymbol {
            return "\(formattedAmount) \(amount.symbol)"
        } else {
            return formattedAmount
        }
    }
}
