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
    public let rules: [CryptoFormatterRule]

    public init(
        defaultValue: String = "",
        prefix: String = "",
        hideSymbol: Bool = false,
        rules: [CryptoFormatterRule] = []
    ) {
        self.defaultValue = defaultValue
        self.prefix = prefix
        self.hideSymbol = hideSymbol
        self.rules = rules
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

    // MARK: - Private

    private func formattedValue(for obj: Any?) -> String? {
        let amount: CryptoAmount?

        if let obj = obj as? CryptoAmount {
            amount = obj
        } else if let obj = obj as? CryptoAmountConvertible {
            amount = obj.asCryptoAmount
        } else {
            amount = nil
        }

        guard let amount else { return nil }

        // Apply rule for token
        var token: AnyToken = amount.token
        for rule in rules {
            token = rule.apply(token)
        }

        let formatter = NumberFormatter()
        formatter.groupingSize = 3
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = Int(token.maxFractionDigit)

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
            return "\(formattedAmount) \(token.symbol)"
        }
    }
}

public struct CryptoFormatterRule {
    let apply: (AnyToken) -> AnyToken

    /// Override max fraction digit for native ethereum.
    public static let nativeEthereumMaxDigit: Self = .init { token in
        if token.tokenPrimaryKey == "native-ethereum" && token.decimals == 18 {
            return SomeToken(
                tokenPrimaryKey: token.tokenPrimaryKey,
                symbol: token.symbol,
                name: token.name,
                decimals: token.decimals,
                maxFractionDigit: 8
            )
        }

        return token
    }
}
