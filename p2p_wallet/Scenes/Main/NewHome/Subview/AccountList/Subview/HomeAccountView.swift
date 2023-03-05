//
//  HomeAccountView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 04.03.2023.
//

import KeyAppUI
import SwiftUI

struct HomeAccountView: View {
    let iconSize: CGFloat = 50
    let rendable: any RendableAccount

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            switch rendable.icon {
            case let .url(url):
                CoinLogoImageViewRepresentable(size: iconSize, args: .manual(preferredImage: nil, url: url, key: "", wrapped: rendable.wrapped))
                    .frame(width: iconSize, height: iconSize)
            case let .image(image):
                CoinLogoImageViewRepresentable(size: iconSize, args: .manual(preferredImage: image, url: nil, key: "", wrapped: rendable.wrapped))
                    .frame(width: iconSize, height: iconSize)
            case let .random(seed):
                CoinLogoImageViewRepresentable(size: iconSize, args: .manual(preferredImage: nil, url: nil, key: seed, wrapped: rendable.wrapped))
                    .frame(width: iconSize, height: iconSize)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(rendable.title)
                    .font(uiFont: .font(of: .text2))
                    .foregroundColor(Color(Asset.Colors.night.color))
                Text(rendable.subtitle)
                    .font(uiFont: .font(of: .label1))
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            Spacer()

            switch rendable.detail {
            case let .text(text):
                Text(text)
                    .font(uiFont: .font(of: .text3, weight: .semibold))
                    .foregroundColor(Color(Asset.Colors.night.color))
            case .button:
                Text("Some button")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            rendable.onTap?()
        }
    }
}

struct HomeAccountView_Previews: PreviewProvider {
    static var previews: some View {
        HomeAccountView(
            rendable: RendableMockAccount(
                id: "123",
                icon: .image(.solanaIcon),
                wrapped: true,
                title: "Solana",
                subtitle: "0.1747 SOL",
                detail: .text("$ 3.67"),
                extraAction: .visiable(action: {}),
                tags: []
            )
        )
    }
}
