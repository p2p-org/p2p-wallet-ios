//
//  Double+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/11/2020.
//

import Foundation

extension Optional where Wrapped == Double {
    public func toString(maximumFractionDigits: Int = 3, showPlus: Bool = false, showMinus: Bool = true, groupingSeparator: String? = " ") -> String {
        orZero.toString(maximumFractionDigits: maximumFractionDigits, showPlus: showPlus, showMinus: showMinus, groupingSeparator: groupingSeparator)
    }
    
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
    
    static func / (left: Double?, right: Double?) -> Double {
        let right = right.orZero
        if right == 0 {return 0}
        return left.orZero / right
    }
}

extension Double {
    public var readableString: String {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = false
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = (self < 1000) ? 4 : 2
        return formatter.string(from: self as NSNumber) ?? "0"
    }
    
    public func toString(maximumFractionDigits: Int = 3, showPlus: Bool = false, showMinus: Bool = true, groupingSeparator: String? = " ") -> String {
        let formatter = NumberFormatter()
        formatter.groupingSize = 3
        formatter.numberStyle = .decimal
        if let groupingSeparator = groupingSeparator {
            formatter.groupingSeparator = groupingSeparator
        }
        
        formatter.locale = Locale.current
        if showPlus {
            formatter.positivePrefix = formatter.plusSign
        }

        if self > 1000 {
            formatter.maximumFractionDigits = 2
        } else if self < 100 {
            formatter.maximumFractionDigits = maximumFractionDigits
        } else {
            formatter.maximumFractionDigits = 2
        }
        
        let number = showMinus ? self: abs(self)
        
        return (formatter.string(from: number as NSNumber) ?? "0")
    }
    
    func rounded(decimals: Int?) -> Double {
        guard let decimals = decimals else {return self}
        let realAmount = self.toString(maximumFractionDigits: decimals, groupingSeparator: nil)
        return realAmount.double ?? self
    }
}
