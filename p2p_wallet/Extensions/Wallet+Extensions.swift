//
//  Wallet+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/06/2021.
//

import Foundation

extension Wallet {
    mutating func updateBalance(diff: Double) {
        guard diff != 0 else {return}
        
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
    
    mutating func increaseBalance(diffInLamports: SolanaSDK.Lamports) {
        let currentBalance = lamports ?? 0
        lamports = currentBalance + diffInLamports
    }
    
    mutating func decreaseBalance(diffInLamports: SolanaSDK.Lamports) {
        let currentBalance = lamports ?? 0
        if currentBalance >= diffInLamports {
            lamports = currentBalance - diffInLamports
        } else {
            lamports = 0
        }
    }
}
