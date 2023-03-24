//
//  WormholeSendView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.03.2023.
//

import KeyAppKitCore
import KeyAppUI
import Kingfisher
import SolanaSwift // TODO: check if I am needed later when wallet is sent to SendInputTokenView
import SwiftUI

struct WormholeSendInputView: View {
    @ObservedObject var viewModel: WormholeSendInputViewModel
    
    let inputFount = UIFont.font(of: .title2, weight: .bold)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            VStack(alignment: .leading, spacing: 12) {
                Text(RecipientFormatter.format(destination: viewModel.recipient.address))
                    .fontWeight(.bold)
                    .apply(style: .largeTitle)
                
                Text("Would be completed on the Ethereum network")
                    .apply(style: .text3)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            .padding(.bottom, 30)
            
            VStack {
                // Info
                HStack {
                    Text(L10n.youWillSend)
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                    
                    Spacer()
                    
                    Button {
                        viewModel.action.send(.openFees)
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.adapter.fees)
                                .apply(style: .text4)
                                .foregroundColor(Color(Asset.Colors.sky.color))
                            
                            if viewModel.adapter.feesLoading {
                                CircularProgressIndicatorView(
                                    backgroundColor: Asset.Colors.sky.color.withAlphaComponent(0.6),
                                    foregroundColor: Asset.Colors.sky.color
                                )
                                .frame(width: 16, height: 16)
                            } else {
                                Image(uiImage: UIImage.infoSend)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)

                SendInputTokenView(
                    wallet: viewModel.adapter.inputAccount?.data ?? Wallet(token: .eth),
                    isChangeEnabled: true,
                    skeleton: viewModel.adapter.inputAccountSkeleton
                ) {
                    viewModel.action.send(.openPickAccount)
                }
            }
            
            if let account = viewModel.adapter.inputAccount {
                VStack(spacing: 6) {
                    HStack {
                        ZStack(alignment: .leading) {
                            SendInputAmountField(
                                text: $viewModel.input,
                                isFirstResponder: $viewModel.isFirstResponder,
                                textColor: viewModel.adapter.inputColor,
                                countAfterDecimalPoint: viewModel.countAfterDecimalPoint
                            ) { textField in
                                textField.font = inputFount
                                textField.placeholder = "0"
                            }
                            
                            TextButtonView(
                                title: L10n.max.uppercased(),
                                style: .second,
                                size: .small
                            ) {
                                viewModel.maxAction()
                            }
                            .transition(.opacity.animation(.easeInOut))
                            .cornerRadius(radius: 32, corners: .allCorners)
                            .frame(width: 68)
                            .offset(x: viewModel.input.isEmpty
                                ? 16
                                : textWidth(font: inputFount, text: viewModel.input)
                            )
                            .padding(.horizontal, 8)
                            .accessibilityIdentifier("max-button")
                        }
                        .frame(height: 28)
                        
                        Text(viewModel.adapter.inputAccount?.data.token.symbol ?? "")
                            .fontWeight(.bold)
                            .apply(style: .title2)
                    }
                    
                    HStack {
                        Text(viewModel.adapter.amountInFiatString)
                            .apply(style: .text4)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                        
                        Spacer()
                        
                        Text(
                            L10n.tapToSwitchTo(
                                viewModel.inputMode == .crypto ? (viewModel.adapter.inputAccount?.data.token.symbol ?? "") : Defaults.fiat.code
                            )
                        )
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(Asset.Colors.snow.color))
                .cornerRadius(16)
                .padding(.top, 8)
            }
            
            Spacer()
            
            SliderActionButton(
                isSliderOn: $viewModel.isSliderOn,
                data: viewModel.adapter.sliderButton,
                showFinished: viewModel.showFinished
            )
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
        .background(
            Color(Asset.Colors.smoke.color)
                .edgesIgnoringSafeArea(.all)
        )
    }
    
    func textWidth(font: UIFont, text: String) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        return (text as NSString).size(withAttributes: fontAttributes).width
    }
}

struct WormholeSendInputView_Previews: PreviewProvider {
    static var previews: some View {
        WormholeSendInputView(
            viewModel: .init(
                recipient: .init(
                    address: "0xff096cc01a7cc98ae3cd401c1d058baf991faf76",
                    category: .ethereumAddress,
                    attributes: []
                )
            )
        )
    }
}
 
