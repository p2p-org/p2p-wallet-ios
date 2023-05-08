//
//  Wallet+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/01/2023.
//

import Foundation
import KeyAppKitCore

extension Array where Element == Wallet {
    var totalAmountInCurrentFiat: Double {
        reduce(0) { $0 + $1._amountInCurrentFiat }
    }

    var isTotalAmountEmpty: Bool {
        contains(where: { $0.amount > 0 }) == false
    }
}
