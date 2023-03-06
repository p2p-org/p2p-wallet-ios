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
    
    let isSwapAvailable: Bool

    var title: String {
        wallet.token.name
    }

    var amountInToken: String {
        wallet.amount?.tokenAmountFormattedString(symbol: wallet.token.symbol) ?? ""
    }

    var amountInFiat: String {
        wallet.amountInCurrentFiat.fiatAmountFormattedString()
    }

    var actions: [RendableAccountDetailAction] {
        var walletActions: [RendableAccountDetailAction]
        if wallet.isNativeSOL || wallet.token.symbol == "USDC" {
            walletActions = [.buy, .receive(.wallet(wallet)), .send]
        } else {
            walletActions = [.receive(.wallet(wallet)), .send]
        }
        if isSwapAvailable {
            walletActions.append(.swap)
        }
        return walletActions
    }

    var onAction: (RendableAccountDetailAction) -> Void
}
