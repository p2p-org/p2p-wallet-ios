//
//  SendLinkCreatedView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/03/2023.
//

import SwiftUI
import KeyAppUI

struct SendLinkCreatedView: View {
    
    let viewModel: SendLinkCreatedViewModel
    
    var body: some View {
        VStack {
            // Close button
            HStack {
                Spacer()
                Button {
                    viewModel.closeClicked()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .padding(8)
                }
                .foregroundColor(Color(Asset.Colors.night.color))
            }
            
            Spacer()
            
            // Header
            Text(L10n.shareYourLinkToSendMoney)
                .apply(style: .largeTitle)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(Asset.Colors.night.color))
                .padding(.bottom, 24)
            
            // Recipient
            RecipientCell(
                image: Image(uiImage: .sendViaLinkCircleCompleted)
                    .castToAnyView(),
                title: viewModel.formatedAmount,
                subtitle: viewModel.link,
                trailingView: Button(
                    action: {
                        viewModel.copyClicked()
                    },
                    label: {
                        Image(uiImage: .copyFill)
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                )
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
            Text(L10n.ifYouWantToGetYourMoneyBackJustOpenTheLinkByYourself)
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
                    viewModel.shareClicked()
                }
            )
                .frame(height: TextButton.Size.large.height)
                .padding(.bottom, 32)
        }
        .padding(.horizontal, 20)
        .background(Color(Asset.Colors.smoke.color).edgesIgnoringSafeArea(.vertical))
        .onAppear {
            viewModel.onAppear()
        }
    }
}

struct SendLinkCreatedView_Previews: PreviewProvider {
    static var previews: some View {
        SendLinkCreatedView(
            viewModel: SendLinkCreatedViewModel(
                link: "test.com/Ro8Andswf",
                formatedAmount: "7.12 SOL",
                intermediateAccountPubKey: ""
            )
        )
    }
}
