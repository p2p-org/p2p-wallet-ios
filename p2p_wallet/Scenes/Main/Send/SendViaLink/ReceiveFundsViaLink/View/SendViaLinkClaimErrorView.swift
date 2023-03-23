//
//  SendViaLinkClaimErrorView.swift
//  p2p_wallet
//
//  Created by Ivan on 29.03.2023.
//

import SwiftUI
import KeyAppUI

struct SendViaLinkClaimErrorView: View {
    
    @Binding var isLoading: Bool
    let reloadClicked: () -> Void
    let cancelClicked: () -> Void
    
    var body: some View {
        VStack(spacing: 39) {
            Text(L10n.refreshThePageOrCheckBackLater)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .font(uiFont: .font(of: .text3))
            Spacer()
            Image(uiImage: .sendViaLinkClaimError)
            VStack(spacing: 12) {
                TextButtonView(
                    title: L10n.reload,
                    style: .primaryWhite,
                    size: .large,
                    isLoading: isLoading,
                    onPressed: {
                        reloadClicked()
                    }
                )
                .frame(height: 56)
                TextButtonView(
                    title: L10n.cancel,
                    style: .inverted,
                    size: .large,
                    onPressed: {
                        cancelClicked()
                    }
                )
                .frame(height: 56)
            }
        }
        .padding(.horizontal, 16)
        .sheetHeader(title: L10n.failedToGetData, withSeparator: false, bottomPadding: 4)
    }
}
