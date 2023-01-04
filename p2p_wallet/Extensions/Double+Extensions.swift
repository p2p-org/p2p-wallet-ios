//
//  Double+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation

// MARK: - Constants

extension Double {
    /// Maximum slippage value allowed
    static var maxSlippage: Self { 0.5 }
}

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

    var isNilOrZero: Bool {
        orZero == 0
    }
}

// MARK: - Rounding

extension Double {
    func rounded(decimals: Int?) -> Double {
        guard let decimals = decimals else { return self }
        let realAmount = toString(maximumFractionDigits: decimals, groupingSeparator: nil)
        return realAmount.double ?? self
    }

    func rounded(decimals: UInt8?) -> Double {
        guard let decimals = decimals else { return self }
        return rounded(decimals: Int(decimals))
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

    public func fixedDecimal(_ maxDecimal: Int, minDecimal: Int = 0) -> String {
        if maxDecimal <= 0 { return "\(maxDecimal)" }
        if self == 0.0 {
            var r = "0."
            for _ in 0 ..< maxDecimal { r += "0" }
            return r
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.roundingMode = NumberFormatter.RoundingMode.halfUp
        formatter.decimalSeparator = "."
        formatter.minimumFractionDigits = minDecimal
        formatter.maximumFractionDigits = maxDecimal

        return formatter.string(for: self) ?? toString(
            minimumFractionDigits: minDecimal,
            maximumFractionDigits: maxDecimal
        )
    }

    func fiatAmountFormattedString(
        maximumFractionDigits: Int = 2,
        currency: Fiat = Defaults.fiat,
        roundingMode: NumberFormatter.RoundingMode? = nil,
        customFormattForLessThan1E_2: Bool = false
    ) -> String {
        let formattedString: String
        
        if customFormattForLessThan1E_2 && self < 0.01 {
            if currency == .usd {
                formattedString = "< \(currency.symbol) 0.01"
            } else {
                formattedString = "< 0.01 \(currency.symbol)"
            }
            
        } else {
            formattedString = toString(maximumFractionDigits: maximumFractionDigits, roundingMode: roundingMode)
        }
        
        if currency == .usd {
            return "\(currency.symbol) \(formattedString)"
        } else {
            return "\(formattedString) \(currency.symbol)"
        }
    }

    func tokenAmountFormattedString(
        symbol: String,
        maximumFractionDigits: Int = 9,
        roundingMode: NumberFormatter.RoundingMode? = nil
    ) -> String {
        "\(toString(maximumFractionDigits: maximumFractionDigits)) \(symbol)"
    }

    func percentFormat(maximumFractionDigits: Int = 2) -> String {
        "\(toString(maximumFractionDigits: maximumFractionDigits))%"
    }
}
