//
//  ParsedTransaction.Status+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 29/06/2021.
//

import Foundation
import SolanaSwift
import TransactionParser

extension ParsedTransaction.Status {
    var label: String {
        switch self {
        case .requesting:
            return L10n.sending.uppercaseFirst
        case .processing:
            return L10n.pending.uppercaseFirst
        case .confirmed:
            return L10n.completed.uppercaseFirst
        case .error:
            return L10n.error.uppercaseFirst
        }
    }
}
