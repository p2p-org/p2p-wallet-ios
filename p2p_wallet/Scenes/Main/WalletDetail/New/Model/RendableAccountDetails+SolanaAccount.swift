//
//  RendableAccountDetails+SolanaWallet.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.02.2023.
//

import Foundation
import KeyAppBusiness

struct RendableNewSolanaAccountDetails: RendableAccountDetails {
    let account: SolanaAccountsService.Account
    
    let isSwapAvailable: Bool

    var title: String {
        account.data.token.name
    }

    var amountInToken: String {
        account.data.amount?.tokenAmountFormattedString(symbol: account.data.token.symbol) ?? ""
    }

    var amountInFiat: String {
        Double(account.amountInFiat?.value.description ?? "")?.fiatAmountFormattedString() ?? ""
    }

    var actions: [RendableAccountDetailsAction] {
        if account.data.isNativeSOL || account.data.token.symbol == "USDC" {
            return [.buy, .receive(.solanaAccount(account)), .send, .swap(account.data)]
        } else {
            return [.receive(.solanaAccount(account)), .send, .swap(account.data)]
        }
    }

    var onAction: (RendableAccountDetailsAction) -> Void
}
