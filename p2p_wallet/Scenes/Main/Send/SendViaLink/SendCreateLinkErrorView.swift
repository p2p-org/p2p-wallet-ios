//
//  SendCreateLinkErrorView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 02/03/2023.
//

import AnalyticsManager
import SwiftUI
import KeyAppUI
import Resolver

struct SendCreateLinkErrorView: View {
    
    @Injected private var analyticsManager: AnalyticsManager
    
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
        .onAppear {
            analyticsManager.log(event: .sendClickDefaultError)
        }
    }
}

struct SendCreateLinkErrorView_Previews: PreviewProvider {
    static var previews: some View {
        SendCreateLinkErrorView {}
    }
}
