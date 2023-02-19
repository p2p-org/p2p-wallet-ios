//
//  RendableAccountDetail+SolanaWallet.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.02.2023.
//

import Foundation
import SolanaSwift

struct RendableSolanaAccountDetail: RendableAccountDetail {
    let wallet: Wallet

    var amountInToken: String {
        wallet.amount?.tokenAmountFormattedString(symbol: wallet.token.symbol) ?? ""
    }

    var amountInFiat: String {
        wallet.amountInCurrentFiat.fiatAmountFormattedString()
    }

    var actions: [RendableAccountDetailAction] {
        if wallet.isNativeSOL || wallet.token.symbol == "USDC" {
            return [.buy, .receive, .send, .swap]
        } else {
            return [.receive, .send, .swap]
        }
    }
    
    var onAction: (RendableAccountDetailAction) -> Void
}
