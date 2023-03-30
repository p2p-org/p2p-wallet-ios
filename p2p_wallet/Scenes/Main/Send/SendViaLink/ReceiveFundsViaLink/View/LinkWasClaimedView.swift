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
            Button(
                action: {
                    close()
                },
                label: {
                    Text(L10n.okay)
                        .foregroundColor(Color(Asset.Colors.snow.color))
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.night.color))
                        .cornerRadius(12)
                }
            )
        }
    }
}
