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
        account.token.name
    }

    var amountInToken: String {
        account.amount?.tokenAmountFormattedString(symbol: account.token.symbol) ?? ""
    }

    var amountInFiat: String {
        account.amountInFiatDouble.fiatAmountFormattedString()
    }

    var actions: [RendableAccountDetailsAction] {
        if account.token.isNativeSOL || account.token.symbol == "USDC" {
            return [.buy, .receive(.solanaAccount(account)), .send, .swap(account)]
        } else {
            return [.receive(.solanaAccount(account)), .send, .swap(account)]
        }
    }

    var onAction: (RendableAccountDetailsAction) -> Void
}
