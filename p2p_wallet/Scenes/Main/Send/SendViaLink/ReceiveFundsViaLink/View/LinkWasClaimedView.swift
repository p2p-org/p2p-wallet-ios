//
//  LinkWasClaimedView.swift
//  p2p_wallet
//
//  Created by Ivan on 28.03.2023.
//

import SwiftUI
import KeyAppUI

struct LinkWasClaimedView: View {
    
    let close: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                Image(uiImage: .sendViaLinkClaimed)
                Text(L10n.thisOneTimeLinkIsAlreadyClaimed)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .title1, weight: .semibold))
                Text(L10n.youCanTReceiveFundsWithIt)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .text4))
            }
            Spacer()
            TextButtonView(
                title: L10n.okay,
                style: .primaryWhite,
                size: .large,
                onPressed: {
                    close()
                }
            )
            .frame(height: 56)
        }
    }
}
