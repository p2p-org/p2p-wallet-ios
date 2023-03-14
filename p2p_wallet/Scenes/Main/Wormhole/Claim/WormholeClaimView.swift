//
//  WormholeClaimReceiving.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 06.03.2023.
//

import KeyAppUI
import SolanaSwift
import SwiftUI

struct WormholeClaimView: View {
    @ObservedObject var viewModel: WormholeClaimViewModel

    var body: some View {
        VStack(spacing: 0) {
            Text(L10n.confirmClaimingTheTokens)
                .fontWeight(.medium)
                .apply(style: .title2)
                .padding(.top, 16)

            Image(uiImage: .ethereumIcon)
                .resizable()
                .clipShape(Circle())
                .frame(width: 64, height: 64)
                .padding(.top, 28)

            Text(viewModel.model.title)
                .fontWeight(.bold)
                .apply(style: .largeTitle)
                .padding(.top, 16)

            if !viewModel.model.subtitle.isEmpty {
                Text(viewModel.model.subtitle)
                    .apply(style: .text2)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .padding(.top, 4)
            }

            HStack(alignment: .center) {
                Text(L10n.fee)
                Spacer()
                Text(L10n.paidByKeyApp)
                Button {
                    viewModel.action.send(.openFee)
                } label: {
                    Image(uiImage: .info)
                        .resizable()
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(Asset.Colors.snow.color))
            )
            .padding(.top, 32)

            Spacer()

            TextButtonView(title: L10n.claim(viewModel.model.title), style: .primaryWhite, size: .large) {
                viewModel.claim()
            }
            .frame(height: TextButton.Size.large.height)
        }
        .padding(.horizontal, 16)
        .background(
            Color(Asset.Colors.smoke.color)
                .ignoresSafeArea()
        )
    }
}

struct WormholeClaimView_Previews: PreviewProvider {
    static var previews: some View {
        WormholeClaimView(viewModel:
            .init(
                model: .init(
                    icon: URL(string: Token.eth.logoURI!)!,
                    title: "0.999717252 ETH",
                    subtitle: "~ $1 219.87"
                )
            )
        )
    }
}
