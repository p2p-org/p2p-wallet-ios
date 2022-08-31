//
//  TokenCellView.swift
//  p2p_wallet
//
//  Created by Ivan on 05.08.2022.
//

import KeyAppUI
import SolanaSwift
import SwiftUI

struct TokenCellViewItem {
    init(wallet: Wallet) {
        token = wallet.token
        amount = wallet.amount
        amountInCurrentFiat = wallet.amountInCurrentFiat
    }

    init(token: Token) {
        self.token = token
    }

    var token: Token
    var amount: Double?
    var amountInCurrentFiat: Double?
}

struct TokenCellView: View {
    let item: TokenCellViewItem

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            CoinLogoImageViewRepresentable(size: 50, token: item.token)
                .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.token.name)
                    .font(uiFont: .font(of: .text2))
                    .foregroundColor(Color(Asset.Colors.night.color))
                if item.amount != nil {
                    Text(item.amount!.tokenAmount(symbol: item.token.symbol))
                        .font(uiFont: .font(of: .label1))
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                }
            }
            Spacer()
            if item.amountInCurrentFiat != nil {
                Text(item.amountInCurrentFiat!.fiatAmount())
                    .font(uiFont: .font(of: .text3, weight: .semibold))
                    .foregroundColor(Color(Asset.Colors.night.color))
            }
        }.contentShape(Rectangle())
    }
}
