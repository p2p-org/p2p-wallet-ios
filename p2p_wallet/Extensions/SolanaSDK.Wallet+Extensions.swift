//
//  Wallet+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2021.
//

import Foundation
import SolanaPricesAPIs
import SolanaSwift

extension Wallet {
    var name: String {
        token.symbol
    }

    var mintAddress: String {
        token.address
    }

    @available(*, deprecated)
    mutating func updateBalance(diff: Double) {
        guard diff != 0 else { return }

        let currentBalance = lamports ?? 0
        let reduction = abs(diff).toLamport(decimals: token.decimals)

        if diff > 0 {
            lamports = currentBalance + reduction
        } else {
            if currentBalance >= reduction {
                lamports = currentBalance - reduction
            } else {
                lamports = 0
            }
        }
    }

    @available(*, deprecated)
    mutating func increaseBalance(diffInLamports: Lamports) {
        let currentBalance = lamports ?? 0
        lamports = currentBalance + diffInLamports
    }

    @available(*, deprecated)
    mutating func decreaseBalance(diffInLamports: Lamports) {
        let currentBalance = lamports ?? 0
        if currentBalance >= diffInLamports {
            lamports = currentBalance - diffInLamports
        } else {
            lamports = 0
        }
    }
}
