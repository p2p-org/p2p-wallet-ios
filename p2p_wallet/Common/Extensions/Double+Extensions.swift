//
//  Double+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation

// MARK: - Optional operations

extension Optional where Wrapped == Double {
    public var orZero: Double {
        self ?? 0
    }

    static func * (left: Double?, right: Double?) -> Double {
        left.orZero * right.orZero
    }

    static func + (left: Double?, right: Double?) -> Double {
        left.orZero + right.orZero
    }

    static func > (left: Double?, right: Double?) -> Bool {
        left.orZero > right.orZero
    }

    static func >= (left: Double?, right: Double?) -> Bool {
        left.orZero >= right.orZero
    }

    static func < (left: Double?, right: Double?) -> Bool {
        left.orZero < right.orZero
    }

    static func <= (left: Double?, right: Double?) -> Bool {
        left.orZero <= right.orZero
    }

    static func / (left: Double?, right: Double?) -> Double {
        let right = right.orZero
        if right == 0 { return 0 }
        return left.orZero / right
    }
}

// MARK: - Rounding

extension Double {
    func rounded(decimals: Int?, roundingMode: NumberFormatter.RoundingMode? = nil) -> Double {
        guard let decimals = decimals else { return self }
        let realAmount = toString(maximumFractionDigits: decimals, groupingSeparator: "", roundingMode: roundingMode)
        return realAmount.double ?? self
    }

    func rounded(decimals: UInt8?, roundingMode: NumberFormatter.RoundingMode? = nil) -> Double {
        guard let decimals = decimals else { return self }
        return rounded(decimals: Int(decimals), roundingMode: roundingMode)
    }
}

// MARK: - Format

extension Double {
    /// Convert double value to string
    public func toString(
        minimumFractionDigits: Int = 0,
        maximumFractionDigits: Int = 3,
        showPlus: Bool = false,
        showMinus: Bool = true,
        groupingSeparator: String? = nil,
        autoSetMaximumFractionDigits: Bool = false,
        roundingMode: NumberFormatter.RoundingMode? = nil
    ) -> String {
        let formatter = NumberFormatter()
        formatter.groupingSize = 3
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."
        formatter.currencyDecimalSeparator = "."
        formatter.groupingSeparator = " "
        formatter.minimumFractionDigits = minimumFractionDigits
        if let groupingSeparator = groupingSeparator {
            formatter.groupingSeparator = groupingSeparator
        }

        formatter.locale = Locale.current
        if showPlus {
            formatter.positivePrefix = formatter.plusSign
        }

        if !autoSetMaximumFractionDigits {
            formatter.maximumFractionDigits = maximumFractionDigits
        } else {
            if self > 1000 {
                formatter.maximumFractionDigits = 2
            } else if self > 100 {
                formatter.maximumFractionDigits = 4
            } else {
                formatter.maximumFractionDigits = 9
            }
        }

        if let roundingMode = roundingMode {
            formatter.roundingMode = roundingMode
        }

        let number = showMinus ? self : abs(self)
        return formatter.string(from: number as NSNumber) ?? "0"
    }
    
    public func formattedForWallet() -> String {
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        
        if abs(self) >= 1000000 {
            formatter.multiplier = 0.000001
            formatter.positiveSuffix = "M"
        } else if abs(self) >= 1000 {
            formatter.multiplier = 0.001
            formatter.positiveSuffix = "k"
        }
        
        return formatter.string(from: self as NSNumber) ?? "0"
    }

    func fiatAmountFormattedString(
        maximumFractionDigits: Int = 2,
        currency: Fiat = Defaults.fiat,
        roundingMode: NumberFormatter.RoundingMode? = nil,
        customFormattForLessThan1E_2: Bool = false
    ) -> String {
        // amount < 0.01
        if customFormattForLessThan1E_2 && self > 0 && self < 0.01 {
            if currency == .usd {
                return "< \(currency.symbol) 0.01"
            } else {
                return "< 0.01 \(currency.symbol)"
            }
        }

        // amount >= 0.01
        else {
            let formattedString = toString(maximumFractionDigits: maximumFractionDigits, roundingMode: roundingMode)

            if currency == .usd {
                return "\(currency.symbol) \(formattedString)"
            } else {
                return "\(formattedString) \(currency.symbol)"
            }
        }
    }

    func tokenAmountFormattedString(
        symbol: String,
        maximumFractionDigits: Int = 9,
        roundingMode: NumberFormatter.RoundingMode? = nil
    ) -> String {
        "\(toString(maximumFractionDigits: maximumFractionDigits, roundingMode: roundingMode)) \(symbol)"
    }

    func formattedFiat(
        maximumFractionDigits: Int = 2,
        currency: Fiat = .usd,
        roundingMode: NumberFormatter.RoundingMode? = nil
    ) -> String {
        "\(toString(maximumFractionDigits: maximumFractionDigits, roundingMode: roundingMode)) \(currency.code)"
    }
}
