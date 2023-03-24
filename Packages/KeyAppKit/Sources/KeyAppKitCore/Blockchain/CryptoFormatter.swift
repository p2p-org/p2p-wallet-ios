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
    public required init?(coder: NSCoder) {
        fatalError()
    }

    public func string(amount: CryptoAmountConverable) -> String {
        string(for: amount.asCryptoAmount) ?? "N/A"
    }

    public func string(amount: CryptoAmount) -> String {
        string(for: amount) ?? "N/A"
    }

    override public func string(for obj: Any?) -> String? {
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

        var formattedAmount = formatter.string(for: amount.amount) ?? "0"

        if !prefix.isEmpty {
            formattedAmount = prefix + " \(formattedAmount)"
        }

        return "\(formattedAmount) \(amount.symbol)"
    }
}

extension BigUInt {
    static func divide(_ lhs: BigUInt, _ rhs: BigUInt) -> Decimal {
        let (quotient, remainder) = lhs.quotientAndRemainder(dividingBy: rhs)
        return Decimal(string: String(quotient))! + Decimal(string: String(remainder))! / Decimal(string: String(rhs))!
    }
}
