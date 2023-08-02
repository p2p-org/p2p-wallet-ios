//
//  Wallet+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/01/2023.
//

import Foundation
import KeyAppKitCore
import SolanaSwift

extension Array where Element == SolanaAccount {
    var isTotalAmountEmpty: Bool {
        contains(where: { $0.amount > 0 }) == false
    }
}
