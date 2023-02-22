//
//  NewHistoryRendableListOffram+Offram.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.02.2023.
//

import Foundation
import Sell

struct SellRendableListOfframItem: RendableListOfframItem {
    let trx: SellDataServiceTransaction
    
    var onTap: (() -> Void)?
    
    var id: String {
        trx.id
    }
    
    var date: Date {
        trx.createdAt ?? Date()
    }
    
    var status: RendableListOfframStatus {
        switch trx.status {
        case .failed:
            return .error
        default:
            return .ready
        }
    }
    
    var title: String {
        switch trx.status {
        case .waitingForDeposit:
            return L10n.youNeedToSendSOL(trx.baseCurrencyAmount.toString(maximumFractionDigits: 9, groupingSeparator: ""))
        case .pending:
            return L10n.processing
        case .completed:
            return L10n.fundsWereSent
        case .failed:
            return L10n.youVeNotSent
        }
    }
    
    var subtitle: String {
        switch trx.status {
        case .waitingForDeposit:
            return L10n.to("..." + trx.depositWallet.suffix(4))
        case .pending:
            return L10n.toYourBankAccount
        case .completed:
            return L10n.toYourBankAccount
        case .failed:
            return L10n.to("SOL", "Moonpay")
        }
    }
    
    var detail: String {
        return "$" + trx.quoteCurrencyAmount.toString(maximumFractionDigits: 2)
    }
}
