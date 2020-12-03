//
//  Transaction.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/11/2020.
//

import Foundation

struct Transaction {
    enum Status {
        case processing, confirmed
        var localizedString: String {
            switch self {
            case .processing:
                return L10n.processing
            case .confirmed:
                return L10n.confirmed
            }
        }
    }
    
    let id: String
    let amount: Double
    let symbol: String
    var status: Status
}
