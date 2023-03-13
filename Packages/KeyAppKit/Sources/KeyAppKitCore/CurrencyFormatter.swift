//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.03.2023.
//

import Foundation

/// Amount in fiat struct
public struct CurrencyAmount: Hashable {
    public let value: Decimal
    public let currencyCode: String

    public init(value: Decimal, currencyCode: String) {
        self.value = value
        self.currencyCode = currencyCode
    }
}

/// The class for formatting Key App currency
public class CurrencyFormatter: Formatter {
    override public func string(for obj: Any?) -> String? {
        guard let obj = obj as? CurrencyAmount else {
            return nil
        }

        let formatter = NumberFormatter()

        // Set currency mode
        formatter.currencyCode = obj.currencyCode
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en-US")

        // Fix prefix padding
        // formatter.negativePrefix = "\(formatter.negativePrefix!) "
        // formatter.positivePrefix = "\(formatter.positivePrefix!) "

        // Set style
        formatter.groupingSize = 3
        formatter.currencyDecimalSeparator = "."
        formatter.currencyGroupingSeparator = " "
//        formatter.roundingMode = .

        let value: String? = formatter.string(for: obj.value)
        return value
    }
}
