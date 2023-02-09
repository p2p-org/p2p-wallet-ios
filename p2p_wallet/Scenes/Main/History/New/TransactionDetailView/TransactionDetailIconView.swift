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

struct TransactionDetailIconView: View {
    private let size: CGFloat = 64

    let icon: DetailTransactionIcon

    var body: some View {
        Group {
            switch icon {
            case let .icon(image):
                RoundedRectangle(cornerRadius: size/2)
                    .fill(Color(Asset.Colors.rain.color))
                    .overlay(
                        Image(uiImage: image)
                            .renderingMode(.template)
                            .foregroundColor(Color(Asset.Colors.night.color))
                    )
            case let .single(url):
                KFImage
                    .url(url)
                    .setProcessor(
                        DownsamplingImageProcessor(size: .init(width: size*2, height: size*2))
                            |> RoundCornerImageProcessor(cornerRadius: size)
                    )
                    .resizable()
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
            case let .double(from, to):
                ZStack(alignment: .center) {
                    KFImage
                        .url(from)
                        .setProcessor(
                            DownsamplingImageProcessor(size: .init(width: size*2, height: size*2))
                                |> RoundCornerImageProcessor(cornerRadius: size)
                        )
                        .resizable()
                        .cacheMemoryOnly()
                        .fade(duration: 0.25)
                        .frame(width: size, height: size)
                        .offset(x: -size/4)
                    
                    KFImage
                        .url(to)
                        .setProcessor(
                            DownsamplingImageProcessor(size: .init(width: size*2, height: size*2))
                                |> RoundCornerImageProcessor(cornerRadius: size)
                        )
                        .resizable()
                        .cacheMemoryOnly()
                        .fade(duration: 0.25)
                        .frame(width: size, height: size)
                        .offset(x: size/4)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

struct DetailTransactionIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TransactionDetailIconView(icon: .icon(.transactionCloseAccount))
            TransactionDetailIconView(icon: .single(URL(string: Token.nativeSolana.logoURI!)!))
            TransactionDetailIconView(icon: .double(
                URL(string: Token.nativeSolana.logoURI!)!,
                URL(string: Token.renBTC.logoURI!)!
            ))
        }
    }
}
