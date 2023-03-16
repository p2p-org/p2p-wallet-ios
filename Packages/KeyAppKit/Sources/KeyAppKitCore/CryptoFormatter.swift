//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.03.2023.
//

import Foundation
import BigInt

/// Token amount struct
public struct CryptoAmount: Hashable {
    public let amount: Decimal
    public let symbol: String
    public let decimals: UInt8

    public init(bigUInt amount: BigUInt, symbol: String, decimals: UInt8) {
        self.amount = BigUInt.divide(amount, BigUInt(10).power(Int(decimals)))
        self.symbol = symbol
        self.decimals = decimals
    }

    public init(amount: Decimal, symbol: String, decimals: UInt8) {
        self.amount = amount
        self.symbol = symbol
        self.decimals = decimals
    }
}

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

    public func string(amount: CryptoAmount) -> String {
        string(for: amount) ?? "N/A"
    }

    override public func string(for obj: Any?) -> String? {
        guard let obj = obj as? CryptoAmount else {
            return nil
        }

        let formatter = NumberFormatter()
        formatter.groupingSize = 3
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = Int(obj.decimals)

        var formattedAmount = formatter.string(for: obj.amount) ?? "0"

        if !prefix.isEmpty {
            formattedAmount = prefix + " \(formattedAmount)"
        }

        return "\(formattedAmount) \(obj.symbol)"
    }
}

extension BigUInt {
    static func divide(_ lhs: BigUInt, _ rhs: BigUInt) -> Decimal {
        let (quotient, remainder) = lhs.quotientAndRemainder(dividingBy: rhs)
        return Decimal(string: String(quotient))! + Decimal(string: String(remainder))! / Decimal(string: String(rhs))!
    }
}
