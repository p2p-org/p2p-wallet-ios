//
//  SolanaSDK.ParsedTransaction.Status+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/06/2021.
//

import Foundation

extension SolanaSDK.ParsedTransaction.Status {
    var label: String {
        switch self {
        case .requesting:
            return L10n.sending.uppercaseFirst
        case .processing(_):
            return L10n.pending.uppercaseFirst
        case .confirmed:
            return L10n.completed.uppercaseFirst
        case .error(_):
            return L10n.error.uppercaseFirst
        }
    }
    
    var indicatorColor: UIColor {
        switch self {
        case .requesting, .processing(_):
            return .alertOrange
        case .confirmed:
            return .greenConfirmed
        case .error(_):
            return .alert
        }
    }
}
