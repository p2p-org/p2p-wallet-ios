//
//  ProcessingTransaction.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/06/2021.
//

import Foundation

struct ProcessingTransaction {
    enum Status: Equatable {
        case requesting
        case processing(percent: Double)
        case confirmed
    }
    
    var signature: String?
    var status: Status
}
