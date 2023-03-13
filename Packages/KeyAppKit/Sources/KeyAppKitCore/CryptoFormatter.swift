//
//  File.swift
//
//
//  Created by Giang Long Tran on 11.03.2023.
//

import Foundation

/// Token amount struct
public struct CryptoAmount: Hashable {
    public let amount: Decimal
    public let symbol: String
    public let decimals: UInt8
    
    public init(amount: Decimal, symbol: String, decimals: UInt8) {
        self.amount = amount
        self.symbol = symbol
        self.decimals = decimals
    }
}

public class CryptoFormatter: Formatter {
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

        let formattedAmount = formatter.string(for: obj.amount) ?? "0"

        return "\(formattedAmount) \(obj.symbol)"
    }
}
