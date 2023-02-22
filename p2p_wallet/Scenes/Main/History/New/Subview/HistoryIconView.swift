//
//  NewHistoryItemIcon.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 02.02.2023.
//

import SwiftUI
import Kingfisher
import KeyAppUI
import SolanaSwift

struct HistoryIconView: View {
    private let largeSize: CGFloat = 46
    private let smallSize: CGFloat = 29

    let icon: RendableListTransactionItemIcon

    var body: some View {
        Group {
            switch icon {
            case let .icon(image):
                RoundedRectangle(cornerRadius: 21)
                    .fill(Color(Asset.Colors.smoke.color))
                    .overlay(
                        Image(uiImage: image)
                            .renderingMode(.template)
                            .foregroundColor(Color(Asset.Colors.night.color))
                    )
            case let .single(url):
                KFImage
                    .url(url)
                    .setProcessor(
                        DownsamplingImageProcessor(size: .init(width: largeSize*2, height: largeSize*2))
                            |> RoundCornerImageProcessor(cornerRadius: largeSize)
                    )
                    .resizable()
                    .diskCacheExpiration(.days(7))
                    .fade(duration: 0.25)
            case let .double(from, to):
                RoundedRectangle(cornerRadius: 21)
                    .fill(Color(Asset.Colors.smoke.color))
                    .overlay(
                        KFImage
                            .url(from)
                            .setProcessor(
                                DownsamplingImageProcessor(size: .init(width: smallSize*2, height: smallSize*2))
                                    |> RoundCornerImageProcessor(cornerRadius: smallSize)
                            )
                            .resizable()
                            .diskCacheExpiration(.days(7))
                            .fade(duration: 0.25)
                            .frame(width: smallSize, height: smallSize),

                        alignment: .topLeading
                    )
                    .overlay(
                        KFImage
                            .url(to)
                            .setProcessor(
                                DownsamplingImageProcessor(size: .init(width: smallSize*2, height: smallSize*2))
                                    |> RoundCornerImageProcessor(cornerRadius: smallSize)
                            )
                            .resizable()
                            .diskCacheExpiration(.days(7))
                            .fade(duration: 0.25)
                            .frame(width: smallSize, height: smallSize),

                        alignment: .bottomTrailing
                    )
            }
        }
        .frame(width: largeSize, height: largeSize)
    }
}

struct HistoryIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HistoryIconView(icon: .icon(.transactionCloseAccount))
            HistoryIconView(icon: .single(URL(string: Token.nativeSolana.logoURI!)!))
            HistoryIconView(icon: .double(
                URL(string: Token.nativeSolana.logoURI!)!,
                URL(string: Token.renBTC.logoURI!)!
            ))
        }
    }
}
