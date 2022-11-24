//
//  SendInputView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.11.2022.
//

import SwiftUI
import KeyAppUI

struct SendInputView: View {
    @ObservedObject var viewModel: SendInputViewModel

    var body: some View {
        ZStack(alignment: .top) {
            Color(Asset.Colors.smoke.color)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text(L10n.youWillSend)
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.mountain.color))

                    Spacer()
                    Text(viewModel.feeTitle)
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.sky.color))

                    Button(action: viewModel.feeInfoPressed.send, label: {
                        Image(uiImage: UIImage.infoSend)
                            .resizable()
                            .frame(width: 16, height: 16)
                    })
                }
                .padding(.horizontal, 4)

                SendInputTokenView(viewModel: viewModel.tokenViewModel)

                SendInputAmountView(viewModel: viewModel.inputAmountViewModel)

                Spacer()

                SendInputActionButtonView(viewModel: viewModel.actionButtonViewModel)
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
            .padding(.bottom, 16)
        }
    }
}

struct SendInputView_Previews: PreviewProvider {
    static var previews: some View {
        SendInputView(viewModel: .init(recipient: .init(
            address: "8JmwhgewSppZ2sDNqGZoKu3bWh8wUKZP8mdbP4M1XQx1",
            category: .solanaAddress,
            hasFunds: false
        )))
    }
}
