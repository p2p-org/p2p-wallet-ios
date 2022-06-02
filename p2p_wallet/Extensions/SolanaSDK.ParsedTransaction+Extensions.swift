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
        switch value {
        case is CreateAccountTransaction:
            return L10n.createAccount
        case is CloseAccountTransaction:
            return L10n.closeAccount
        case let transaction as TransferTransaction:
            switch transaction.transferType {
            case .send:
                return L10n.transfer
            case .receive:
                return L10n.receive
            default:
                return L10n.transfer
            }

        case is SwapTransaction:
            return L10n.swap
        default:
            break
        }

        return L10n.transaction
    }

    var icon: UIImage {
        switch value {
        case is CreateAccountTransaction:
            return .transactionCreateAccount
        case is CloseAccountTransaction:
            return .transactionCloseAccount
        case let transaction as TransferTransaction:
            switch transaction.transferType {
            case .send:
                return .transactionSend
            case .receive:
                return .transactionReceive
            default:
                break
            }
        case is SwapTransaction:
            return .transactionSwap
        default:
            break
        }
        return .transactionUndefined
    }
}
