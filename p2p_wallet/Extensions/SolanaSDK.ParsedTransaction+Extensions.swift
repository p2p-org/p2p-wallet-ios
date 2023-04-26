//
//  ParsedTransaction+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/04/2021.
//

import Foundation
import SolanaSwift
import TransactionParser

extension ParsedTransaction {
    var label: String {
        switch info {
        case is CreateAccountInfo:
            return L10n.createAccount
        case is CloseAccountInfo:
            return L10n.closeAccount
        case let transaction as TransferInfo:
            switch transaction.transferType {
            case .send:
                return L10n.transfer
            case .receive:
                return L10n.receive
            default:
                return L10n.transfer
            }

        case is SwapInfo:
            return L10n.swap
        default:
            break
        }

        return L10n.transaction
    }
}
