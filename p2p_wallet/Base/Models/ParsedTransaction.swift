//
//  ProcessingTransaction.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/06/2021.
//

import Foundation

struct ParsedTransaction: Hashable {
    enum Status: Equatable, Hashable {
        case requesting
        case processing(percent: Double)
        case confirmed
    }
    
    var status: Status
    var parsed: SolanaSDK.AnyTransaction?
}
