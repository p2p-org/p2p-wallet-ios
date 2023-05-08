//
//  TokenCellView.swift
//  p2p_wallet
//
//  Created by Ivan on 05.08.2022.
//

import KeyAppUI
import SolanaSwift
import SwiftUI
import KeyAppKitCore

struct TokenCellViewItem: Hashable {
    init(wallet: Wallet) {
        token = wallet.token
        amount = wallet.amount
        amountInCurrentFiat = wallet._priceInCurrentFiat == nil ? nil : wallet._amountInCurrentFiat
    }

    init(token: Token, amount: Double? = nil, fiat: Fiat? = nil) {
        self.token = token
        self.amount = amount
        self.fiat = fiat
    }

    var token: Token
    var amount: Double?
    var fiat: Fiat?
    var amountInCurrentFiat: Double?
}

struct TokenCellView: View {
    let item: TokenCellViewItem
    let appearance: Appearance

    init(item: TokenCellViewItem, appearance: Appearance = .main) {
        self.item = item
        self.appearance = appearance
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            CoinLogoImageViewRepresentable(size: appearance.logoImageSize, args: .token(item.token))
                .frame(width: appearance.logoImageSize, height: appearance.logoImageSize)
                .accessibility(identifier: "TokenCellView.CoinLogoImageView")
            VStack(alignment: .leading, spacing: appearance.textPadding) {
                Text(item.token.name)
                    .font(uiFont: .font(of: .text2))
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .accessibility(identifier: "TokenCellView.item.token.name")
                if item.amount != nil {
                    Text(item.amount!.tokenAmountFormattedString(symbol: item.token.symbol))
                        .font(uiFont: .font(of: .label1))
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                        .accessibility(identifier: "TokenCellView.item.amount")
                }
            }
            Spacer()
            if item.amountInCurrentFiat != nil {
                Text(item.amountInCurrentFiat!.fiatAmountFormattedString(customFormattForLessThan1E_2: true))
                    .font(uiFont: .font(of: .text3, weight: .semibold))
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .accessibility(identifier: "TokenCellView.item.amountInCurrentFiat")
            }
        }.contentShape(Rectangle())
    }
}

extension TokenCellView {
    struct Appearance {
        let logoImageSize: CGFloat
        let textPadding: CGFloat

        static let main = Appearance(logoImageSize: 50, textPadding: 4)
        static let other = Appearance(logoImageSize: 48, textPadding: 6)
    }
}
