//
//  WormholeClaimFee.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 06.03.2023.
//

import KeyAppUI
import SwiftUI

struct WormholeClaimFee: View {
    let close: (() -> Void)?

    var body: some View {
        VStack {
            Image(uiImage: .fee)
                .padding(.top, 33)

            HStack {
                Circle()
                    .fill(Color(Asset.Colors.smoke.color))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(uiImage: .lightningFilled)
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .frame(width: 15, height: 21.5)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.enjoyFreeTransactions)
                        .fontWeight(.semibold)
                        .apply(style: .text1)
                    Text(L10n.WithKeyAppTheFirstTransactionIsFree.alsoAllTheTransactionsAbove300AreFree)
                        .apply(style: .text4)
                }
            }
            .padding(.all, 16)
            .background(Color(Asset.Colors.cloud.color))
            .cornerRadius(12)
            .padding(.top, 20)

            VStack(spacing: 24) {
                WormholeFeeView(title: "You will get", subtitle: "0.999717252 WETH", detail: "~ $1,215.75")
                WormholeFeeView(title: "You will get", subtitle: "0.999717252 WETH", detail: "Free")
                WormholeFeeView(title: "You will get", subtitle: "0.999717252 WETH", detail: "~ $1,215.75")
            }
            .padding(.top, 16)

            TextButtonView(title: L10n.ok, style: .second, size: .large, onPressed: close)
                .frame(height: TextButton.Size.large.height)
                .padding(.top, 20)
        }
        .padding(.horizontal, 16)
    }
}

private struct WormholeFeeView: View {
    let title: String
    let subtitle: String
    let detail: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .apply(style: .text3)
                Text(subtitle)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            Spacer()
            Text(detail)
                .apply(style: .label1)
                .foregroundColor(Color(Asset.Colors.mountain.color))
        }
    }
}

struct WormholeClaimFee_Previews: PreviewProvider {
    static var previews: some View {
        WormholeClaimFee {}
    }
}
