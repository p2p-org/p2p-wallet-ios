//
//  Wallet+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/01/2023.
//

import Foundation
import SolanaSwift

extension Array where Element == Wallet {
    var isTotalAmountEmpty: Bool {
        contains { $0.amount > 0 } == false
    }
}
