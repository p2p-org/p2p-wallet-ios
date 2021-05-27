//
//  PendingTransaction.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/05/2021.
//

import Foundation

struct PendingTransaction: Equatable {
    let signature: String
    let walletAddress: String
    let change: Double // change in amount
}
