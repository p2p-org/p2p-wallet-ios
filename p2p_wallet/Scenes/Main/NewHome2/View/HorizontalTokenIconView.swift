//
//  HorizontalTokenIconView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 23/06/2023.
//

import KeyAppKitCore
import KeyAppUI
import Kingfisher
import SolanaSwift
import SwiftUI

struct HorizontalTokenIconView: View {
    let icons: [URL]

    var body: some View {
        HStack(spacing: -16) {
            ForEach(icons, id: \.absoluteString) { iconURL in
                Circle()
                    .fill(Color(Asset.Colors.rain.color))
                    .frame(width: 36, height: 36)
                    .overlay {
                        KFImage
                            .url(iconURL)
                            .resizable()
                            .frame(width: 34, height: 34)
                    }
            }
            
        }
        //.environment(\.layoutDirection, .rightToLeft)
    }
}

struct HorizontalTokenIconView_Previews: PreviewProvider {
    static var previews: some View {
        HorizontalTokenIconView(
            icons: [
                SolanaToken.usdc,
                SolanaToken.usdt,
                SolanaToken.stSOL,
            ].map { token -> URL? in
                if let url = token.logoURI {
                    return URL(string: url)
                } else {
                    return nil
                }
            }
            .compactMap { $0 }
        )
    }
}
