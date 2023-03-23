//
//  File.swift
//
//
//  Created by Giang Long Tran on 23.03.2023.
//

import Foundation

extension Decimal {
    var wholePart: Self {
        var result = Decimal()
        var mutableSelf = self
        NSDecimalRound(&result, &mutableSelf, 0, self >= 0 ? .down : .up)
        return result
    }
}
