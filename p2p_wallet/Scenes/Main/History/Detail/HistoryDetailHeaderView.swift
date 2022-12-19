//
//  HistoryHeaderView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.12.2022.
//

import KeyAppUI
import SwiftUI
import SolanaSwift

struct HistoryDetailHeaderView: View {
    let token: Token
    let title: String
    let subtitle: String

    var body: some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
                .frame(height: 208)
            tokenView
        }
    }

    private var tokenView: some View {
        VStack(alignment: .center, spacing: 16) {
            CoinLogoImageViewRepresentable(size: 64, token: token)
                .frame(width: 64, height: 64)
            VStack(alignment: .center, spacing: 4) {
                Text(title)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .largeTitle, weight: .bold))
                Text(subtitle)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .font(uiFont: .font(of: .text2))
            }
        }
    }
}

struct HistoryDetailHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryDetailHeaderView(
            token: Token.usdc,
            title: "- $5 268.65",
            subtitle: "1.36 SOL"
        ).frame(height: 200)
    }
}
