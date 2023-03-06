//
//  WormholeClaimReceiving.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 06.03.2023.
//

import KeyAppUI
import SwiftUI

struct WormholeClaimView: View {
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

            Text("0.999717252 WETH")
                .fontWeight(.bold)
                .apply(style: .largeTitle)
                .padding(.top, 16)

            Text("~ $1 219.87")
                .apply(style: .text2)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .padding(.top, 4)

            HStack(alignment: .center) {
                Text(L10n.fee)
                Spacer()
                Text(L10n.paidByKeyApp)
                Image(uiImage: .info)
                    .resizable()
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(Asset.Colors.snow.color))
            )
            .padding(.top, 32)
            
            Spacer()
            
            TextButtonView(title: L10n.claim("0.999717252 WETH"), style: .primaryWhite, size: .large)
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
        WormholeClaimView()
    }
}
