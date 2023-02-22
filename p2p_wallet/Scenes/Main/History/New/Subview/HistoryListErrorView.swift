//
//  NewHistoryListErrorView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 16.02.2023.
//

import KeyAppUI
import SwiftUI

struct HistoryListErrorView: View {
    let onTryAgain: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: .catFail)
                .padding(.top, 24)

            Text(L10n.oopsSomethingHappened)
                .padding(.top, 32)
                .padding(.bottom, 24)

            TextButtonView(title: L10n.tryAgain, style: .second, size: .large) {
                onTryAgain()
            }
            .frame(height: TextButton.Size.large.height)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(Asset.Colors.snow.color))
        .cornerRadius(radius: 16, corners: .allCorners)
    }
}

struct HistoryListErrorView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryListErrorView() {}
    }
}
