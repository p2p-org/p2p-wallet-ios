//
//  TokenCellView.swift
//  p2p_wallet
//
//  Created by Ivan on 05.08.2022.
//

import KeyAppUI
import SolanaSwift
import SwiftUI

struct TokenCellView: View {
    let wallet: Wallet

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            CoinLogoImageViewRepresentable(size: 50, token: wallet.token)
                .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 4) {
                Text(wallet.token.name)
                    .font(uiFont: .font(of: .text2))
                    .foregroundColor(Color(Asset.Colors.night.color))
                Text(wallet.amount?.tokenAmount(symbol: wallet.token.symbol) ?? "")
                    .font(uiFont: .font(of: .label1))
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            Spacer()
            Text(wallet.amountInCurrentFiat.fiatAmount())
                .font(uiFont: .font(of: .text3, weight: .semibold))
                .foregroundColor(Color(Asset.Colors.night.color))
        }
        .contentShape(Rectangle())
    }
}
