//
//  RendableAccountDetail+SolanaWallet.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.02.2023.
//

import Foundation
import KeyAppBusiness

struct RendableNewSolanaAccountDetail: RendableAccountDetail {
    let account: SolanaAccountsService.Account
    
    let isSwapAvailable: Bool

    var title: String {
        account.data.token.name
    }

    var amountInToken: String {
        account.data.amount?.tokenAmountFormattedString(symbol: account.data.token.symbol) ?? ""
    }

    var amountInFiat: String {
        account.amountInFiat.fiatAmountFormattedString()
    }

    var actions: [RendableAccountDetailAction] {
        var walletActions: [RendableAccountDetailAction]
        if account.data.isNativeSOL || account.data.token.symbol == "USDC" {
            walletActions = [.buy, .receive(.solanaAccount(account)), .send, .swap]
            return [.buy, .receive(.solanaAccount(account)), .send, .swap(nil)]
        } else {
            return [.receive(.solanaAccount(account)), .send, .swap(nil)]
        }
    }

    var onAction: (RendableAccountDetailAction) -> Void
}
