//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.03.2023.
//

import BigInt
import Foundation

/// Any token for easy converable
public protocol AnyToken {
    var tokenPrimaryKey: String { get }

    var symbol: String { get }

    var name: String { get }

    var decimals: UInt8 { get }
}

/// Token amount struct
public struct CryptoAmount: Hashable {
    public let value: BigUInt

    public var amount: Decimal {
        BigUInt.divide(value, BigUInt(10).power(Int(decimals)))
    }

    public let symbol: String

    public let decimals: UInt8

    public let smartContract: String

    public init(amount: BigUInt, token: AnyToken) {
        self.value = amount
        self.symbol = token.symbol
        self.decimals = token.decimals
        self.smartContract = token.tokenPrimaryKey
    }

    public init(uint64 amount: UInt64, token: AnyToken) {
        self.init(
            amount: BigUInt(integerLiteral: amount),
            token: token
        )
    }

    public init(bigUIntString amount: String, token: AnyToken) {
        self.init(
            amount: BigUInt(stringLiteral: amount),
            token: token
        )
    }

    public init(token: AnyToken) {
        self.init(amount: 0, token: token)
    }

    public init?(floatString amount: String, token: AnyToken) {
        let parts = amount.components(separatedBy: ".")

        if parts.count == 1 {
            let intValue = parts.first!
            let zeroPadding = String(repeating: "0", count: Int(token.decimals))

            let number = intValue + zeroPadding

            self.init(
                bigUIntString: number,
                token: token
            )

            return
        }

        guard parts.count == 2 else { return nil }

        let integerPart = parts.first!
        var floatingPart = parts.last!

        var zeroPaddingCount = Int(token.decimals) - floatingPart.count
        var zeroPaddingStr = ""

        if zeroPaddingCount > 0 {
            zeroPaddingStr = .init(repeating: "0", count: zeroPaddingCount)
        } else if zeroPaddingCount < 0 {
            floatingPart = String(floatingPart.prefix(-zeroPaddingCount))
        }

        let number = integerPart + floatingPart + zeroPaddingStr

        self.init(
            bigUIntString: number,
            token: token
        )
    }

    public func toFiatAmount(price: TokenPrice) throws -> CurrencyAmount {
        guard price.smartContract == smartContract else {
            throw ConvertError.invalidPriceForToken(expected: symbol, actual: price.symbol)
        }

        return .init(value: amount * (price.value ?? 0), currencyCode: price.currencyCode)
    }

    public func unsafeToFiatAmount(price: TokenPrice) -> CurrencyAmount {
        guard price.smartContract == smartContract else {
            return .init(value: 0, currencyCode: price.currencyCode)
        }

        return .init(value: amount * (price.value ?? 0), currencyCode: price.currencyCode)
    }
}

extension CryptoAmount: Comparable {
    public static func < (lhs: CryptoAmount, rhs: CryptoAmount) -> Bool {
        guard lhs.smartContract == rhs.smartContract else {
            return false
        }

        return lhs.value < rhs.value
    }
}

public protocol CryptoAmountConverable {
    var asCryptoAmount: CryptoAmount { get }
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
