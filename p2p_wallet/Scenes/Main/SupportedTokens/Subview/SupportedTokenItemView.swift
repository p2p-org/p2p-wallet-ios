//
//  SupportedTokenItemView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07.03.2023.
//

import KeyAppUI
import Kingfisher
import SwiftUI

struct SupportedTokenItemView: View {
    let iconSize: CGFloat = 48
    let networkSize: CGFloat = 16

    let item: SupportedTokenItem

    var body: some View {
        HStack {
            switch item.icon {
            case .placeholder:
                placeholderIcon
            case let .image(image):
                Circle()
                    .fill(Color(Asset.Colors.smoke.color))
                    .overlay(Image(uiImage: image))
                    .clipped()
                    .frame(width: iconSize, height: iconSize)
            case let .url(url):
                KFImage
                    .url(url)
                    .setProcessor(
                        DownsamplingImageProcessor(size: .init(width: iconSize * 2, height: iconSize * 2))
                            |> RoundCornerImageProcessor(cornerRadius: iconSize)
                    )
                    .placeholder {
                        placeholderIcon
                    }
                    .resizable()
                    .diskCacheExpiration(.days(7))
                    .fade(duration: 0.25)
                    .frame(width: iconSize, height: iconSize)
            }

            VStack(alignment: .leading) {
                Text(item.name)
                    .apply(style: .text3)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color(Asset.Colors.night.color))
                Text(item.symbol)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }

            Spacer()

            switch true {
            case item.availableNetwork.contains(.solana) && item.availableNetwork.contains(.ethereum):
                ZStack {
                    Image(.ethereumIcon)
                        .resizable()
                        .frame(width: networkSize, height: networkSize)
                        .cornerRadius(networkSize)

                    Image(.solanaIcon)
                        .resizable()
                        .frame(width: networkSize, height: networkSize)
                        .cornerRadius(networkSize)
                        .background(
                            Circle()
                                .fill(.white)
                                .frame(width: networkSize+1, height: networkSize+1)
                        )
                        .offset(x: -10)
                }

            case item.availableNetwork.contains(.ethereum):
                Image(.ethereumIcon)
                    .resizable()
                    .frame(width: networkSize, height: networkSize)
                    .cornerRadius(networkSize)
            case item.availableNetwork.contains(.solana):
                Image(.solanaIcon)
                    .resizable()
                    .frame(width: networkSize, height: networkSize)
                    .cornerRadius(networkSize)
            default:
                SwiftUI.EmptyView()
            }
        }
        .padding(.horizontal, 16)
    }

    var placeholderIcon: some View {
        Circle()
            .fill(Color(Asset.Colors.smoke.color))
            .overlay(
                Image(.imageOutlineIcon)
                    .renderingMode(.template)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            )
            .clipped()
            .frame(width: iconSize, height: iconSize)
    }
}

struct SupportedTokenItemView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SupportedTokenItemView(
                item: SupportedTokenItem(
                    icon: .image(.ethereumIcon),
                    name: "USD Coin",
                    symbol: "USDC",
                    availableNetwork: [.solana, .ethereum]
                )
            )
            SupportedTokenItemView(
                item: SupportedTokenItem(
                    icon: .image(.imageOutlineIcon),
                    name: "USD Coin",
                    symbol: "USDC",
                    availableNetwork: [.solana, .ethereum]
                )
            )
        }
    }
}
