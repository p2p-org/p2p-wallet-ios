//
//  Wallet+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/01/2023.
//

import Foundation
import SolanaSwift

extension Array where Element == Wallet {
    var totalAmountInCurrentFiat: Double {
        reduce(0) { $0 + $1.amountInCurrentFiat }
    }
    
    var isTotalBalanceEmpty: Bool {
        totalAmountInCurrentFiat == 0
    }
}
