//
//  SendLinkCreatedView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/03/2023.
//

import SwiftUI
import KeyAppUI

struct SendLinkCreatedView: View {
    let link: String
    let formatedAmount: String
    let onClose: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack {
            // Close button
            HStack {
                Spacer()
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .foregroundColor(Color(Asset.Colors.night.color))
            }
            
            Spacer()
            
            // Header
            Text(L10n.theLinkIsReadyReceiverWillBeAbleToClaimFunds)
                .apply(style: .largeTitle)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(Asset.Colors.night.color))
                .padding(.bottom, 24)
            
            // Recipient
            RecipientCell(
                image: Image(uiImage: .sendViaLinkCircleCompleted)
                    .castToAnyView(),
                title: L10n.sendViaLink,
                subtitle: link,
                trailingView: Text(formatedAmount)
                    .font(uiFont: UIFont.font(of: .text3, weight: .semibold))
                    .castToAnyView()
            )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundColor(Color(Asset.Colors.snow.color))
                )
                .padding(.bottom, 28)
            
            // Subtitle
            Text(L10n.TheLinkWorksOnly1TimeForAnyUsers.ifYouLogInYourselfTheFundsWillBeReturnedToYourAccount)
                .apply(style: .text3)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .padding(.horizontal, 16)
            
            Spacer()
            
            // Button
            TextButtonView(
                title: L10n.share,
                style: .primaryWhite,
                size: .large,
                onPressed: {
                    onShare()
                }
            )
                .frame(height: TextButton.Size.large.height)
                .padding(.bottom, 32)
        }
        .padding(.horizontal, 20)
            .background(Color(Asset.Colors.smoke.color).edgesIgnoringSafeArea(.vertical))
    }
}

struct SendLinkCreatedView_Previews: PreviewProvider {
    static var previews: some View {
        SendLinkCreatedView(
            link: "key.app/Ro8Andswf",
            formatedAmount: "7.12 SOL",
            onClose: {},
            onShare: {}
        )
    }
}
