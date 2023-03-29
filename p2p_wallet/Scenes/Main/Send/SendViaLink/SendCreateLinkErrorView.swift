//
//  SendCreateLinkErrorView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 02/03/2023.
//

import SwiftUI
import KeyAppUI

struct SendCreateLinkErrorView: View {
    let onGoBack: () -> Void
    var body: some View {
        VStack {
            Spacer()
            
            ErrorView(
                title: L10n.sorry,
                subtitle: L10n.OopsSomethingWentWrong
                    .pleaseTryAgainLater
            )
            
            Spacer()
            
            // Button
            TextButtonView(
                title: L10n.goBack,
                style: .primaryWhite,
                size: .large,
                onPressed: {
                    onGoBack()
                }
            )
                .frame(height: TextButton.Size.large.height)
                .padding(.bottom, 32)
        }
            .padding(.horizontal, 20)
            .background(
                Color(Asset.Colors.snow.color)
                    .edgesIgnoringSafeArea(.top)
            )
    }
}

struct SendCreateLinkErrorView_Previews: PreviewProvider {
    static var previews: some View {
        SendCreateLinkErrorView {}
    }
}
