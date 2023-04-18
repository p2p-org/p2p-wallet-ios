//
//  RendableAccountDetails+SolanaWallet.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.02.2023.
//

import Foundation
import KeyAppKitCore

struct RendableNewSolanaAccountDetails: RendableAccountDetails {
    let account: SolanaAccount
    
    let isSwapAvailable: Bool

    var title: String {
        account.data.token.name
    }

    var amountInToken: String {
        account.data.amount?.tokenAmountFormattedString(symbol: account.data.token.symbol) ?? ""
    }

    var amountInFiat: String {
        account.amountInFiatDouble.fiatAmountFormattedString()
    }

    var actions: [RendableAccountDetailsAction] {
        var walletActions: [RendableAccountDetailsAction]
        if account.data.isNativeSOL || account.data.token.symbol == "USDC" {
            walletActions = [.buy, .receive(.solanaAccount(account)), .send, .swap(account.data)]
            return [.buy, .receive(.solanaAccount(account)), .send, .swap(account.data)]
        } else {
            return [.receive(.solanaAccount(account)), .send, .swap(account.data)]
        }
    }

    var onAction: (RendableAccountDetailsAction) -> Void
}
