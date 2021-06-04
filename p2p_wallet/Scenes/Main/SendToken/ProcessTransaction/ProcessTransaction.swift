//
//  ProcessTransaction.swift
//  p2p_wallet
//
//  Created by Chung Tran on 02/06/2021.
//

import Foundation

struct ProcessTransaction {
    enum TransactionType {
        case send(from: Wallet, to: String, amount: Double)
        case swap(from: Wallet, to: Wallet, inputAmount: Double, estimatedAmount: Double)
    }
    enum TransactionStatus {
        case processing // with or without transaction id
        case confirmed
        case error(Error)
    }
}
