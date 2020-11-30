//
//  Transaction.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/11/2020.
//

import Foundation

struct Transaction {
    enum Status {
        case processing, done
        var localizedString: String {
            switch self {
            case .processing:
                return L10n.processing
            case .done:
                return L10n.done
            }
        }
    }
    
    let id: String
    let amount: Double
    let symbol: String
    let status: Status
}
