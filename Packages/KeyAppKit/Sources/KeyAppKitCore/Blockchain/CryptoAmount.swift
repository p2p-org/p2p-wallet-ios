//
//  File.swift
//
//
//  Created by Giang Long Tran on 24.03.2023.
//

import BigDecimal
import BigInt
import Foundation

/// Token amount struct
public struct CryptoAmount: Hashable, Codable, Equatable {
    /// Token metadata
    public let token: SomeToken

    public let value: BigUInt

    public var amount: BigDecimal {
        BigDecimal(integerValue: BigInt(value), scale: Int(token.decimals))
    }

    public init(amount: BigUInt, token: AnyToken) {
        value = amount
        self.token = token.asSomeToken
    }

    public init(uint64 amount: UInt64, token: AnyToken) {
        self.init(
            amount: BigUInt(integerLiteral: amount),
            token: token
        )
    }

    public init(bigUIntString amount: String, token: AnyToken) {
        self.init(
            amount: BigUInt(amount, radix: 10) ?? 0,
            token: token
        )
    }

    public init(token: AnyToken) {
        self.init(amount: 0, token: token)
    }

    public init?(floatString amount: String, token: AnyToken) {
        if amount.isEmpty { return nil }

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

        let zeroPaddingCount = Int(token.decimals) - floatingPart.count
        var zeroPaddingStr = ""

        if zeroPaddingCount > 0 {
            zeroPaddingStr = .init(repeating: "0", count: zeroPaddingCount)
        } else if zeroPaddingCount < 0 {
            floatingPart = String(floatingPart.prefix(Int(token.decimals)))
        }

        let number = integerPart + floatingPart + zeroPaddingStr

        self.init(
            bigUIntString: number,
            token: token
        )
    }

    public func toFiatAmount(price: TokenPrice) throws -> CurrencyAmount {
        guard price.token.tokenPrimaryKey == token.tokenPrimaryKey else {
            throw ConvertError.invalidPriceForToken(expected: token.symbol, actual: price.token.symbol)
        }

        return .init(value: amount * price.value, currencyCode: price.currencyCode)
    }

    public func unsafeToFiatAmount(price: TokenPrice) -> CurrencyAmount {
        guard price.token.tokenPrimaryKey == token.tokenPrimaryKey else {
            return .init(value: 0, currencyCode: price.currencyCode)
        }

        return .init(value: amount * price.value, currencyCode: price.currencyCode)
    }

    public func with(amount: BigUInt) -> Self {
        .init(amount: amount, token: token)
    }
}

extension CryptoAmount: Comparable {
    public static func < (lhs: CryptoAmount, rhs: CryptoAmount) -> Bool {
        guard lhs.token.tokenPrimaryKey == rhs.token.tokenPrimaryKey else {
            return false
        }

        return lhs.value < rhs.value
    }
}

public extension CryptoAmount {
    /// Additional operation. Return left side if they are matching.
    static func + (lhs: Self, rhs: Self) -> Self {
        guard lhs.token == rhs.token else {
            return lhs
        }

        return .init(amount: lhs.value + rhs.value, token: lhs.token)
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        guard lhs.token == rhs.token else {
            return lhs
        }

        return .init(amount: lhs.value - rhs.value, token: lhs.token)
    }

    /// Additonal operation. Return left side if they are matching.
    // static func + (lhs: Self, rhs: Self?) -> Self {
    //    guard let rhs else { return lhs }
    //    return lhs + rhs
    // }
}

extension BigUInt {
    static func toDecimal(_ value: BigUInt, exponent: Int) throws -> Decimal {
        guard let value = Decimal(string: String(value)) else {
            throw ConvertError.enormousValue
        }
        return Decimal(sign: .plus, exponent: exponent, significand: value)
    }
}
