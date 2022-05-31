//
//  SolanaSDK.ParsedTransaction+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/04/2021.
//

import Foundation
import SolanaSwift

extension SolanaSDK.ParsedTransaction {
    var label: String {
        switch value {
        case is SolanaSDK.CreateAccountTransaction:
            return L10n.createAccount
        case is SolanaSDK.CloseAccountTransaction:
            return L10n.closeAccount
        case let transaction as SolanaSDK.TransferTransaction:
            switch transaction.transferType {
            case .send:
                return L10n.transfer
            case .receive:
                return L10n.receive
            default:
                return L10n.transfer
            }

        case is SolanaSDK.SwapTransaction:
            return L10n.swap
        default:
            break
        }

        return L10n.transaction
    }

    var icon: UIImage {
        switch value {
        case is SolanaSDK.CreateAccountTransaction:
            return .transactionCreateAccount
        case is SolanaSDK.CloseAccountTransaction:
            return .transactionCloseAccount
        case let transaction as SolanaSDK.TransferTransaction:
            switch transaction.transferType {
            case .send:
                return .transactionSend
            case .receive:
                return .transactionReceive
            default:
                break
            }
        case is SolanaSDK.SwapTransaction:
            return .transactionSwap
        default:
            break
        }
        return .transactionUndefined
    }
}
