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
public struct CryptoAmount: Hashable {
    public let value: BigUInt

    public var amount: BigDecimal {
        BigDecimal(integerValue: BigInt(value), scale: Int(decimals))
    }

    public let symbol: String

    public let decimals: UInt8

    public let smartContract: String

    public init(amount: BigUInt, token: AnyToken) {
        value = amount
        symbol = token.symbol
        decimals = token.decimals
        smartContract = token.tokenPrimaryKey
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

extension BigUInt {
    static func toDecimal(_ value: BigUInt, exponent: Int) throws -> Decimal {
        guard let value = Decimal(string: String(value)) else {
            throw ConvertError.enormousValue
        }
        return Decimal(sign: .plus, exponent: exponent, significand: value)
    }
}
