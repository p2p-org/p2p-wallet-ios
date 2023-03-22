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
    
    let currencyFormatter: CurrencyFormatter = .init()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            VStack(alignment: .leading, spacing: 12) {
                Text("0x0ea9...f5709c")
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
                    
                    Button {} label: {
                        HStack(spacing: 4) {
                            switch viewModel.state {
                            case .calculating, .initializing:
                                Text("Fees: ")
                                    .apply(style: .text4)
                                    .foregroundColor(Color(Asset.Colors.sky.color))
                                CircularProgressIndicatorView(
                                    backgroundColor: Asset.Colors.sky.color.withAlphaComponent(0.6),
                                    foregroundColor: Asset.Colors.sky.color
                                )
                                .frame(width: 16, height: 16)
                                
                            case let .ready(_, _, fees, _):
                                Text("Fees: \(currencyFormatter.string(amount: fees.totalInFiat))")
                                    .apply(style: .text4)
                                    .foregroundColor(Color(Asset.Colors.sky.color))
                                Image(uiImage: UIImage.infoSend)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            default:
                                SwiftUI.EmptyView()
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)

                switch viewModel.state {
                case let .initializing(input):
                    SendInputTokenView(wallet: input.solanaAccount.data, isChangeEnabled: true, skeleton: true, changeAction: {
                        // TODO: Pass here action from viewModel in https://github.com/p2p-org/p2p-wallet-ios/pull/1080
                    })
                case let .ready(input, _, _, _):
                    SendInputTokenView(wallet: input.solanaAccount.data, isChangeEnabled: true, changeAction: {
                        // TODO: Pass here action from viewModel in https://github.com/p2p-org/p2p-wallet-ios/pull/1080
                    })
                case let .calculating(input):
                    SendInputTokenView(wallet: input.solanaAccount.data, isChangeEnabled: true, changeAction: {
                        // TODO: Pass here action from viewModel in https://github.com/p2p-org/p2p-wallet-ios/pull/1080
                    })
                case let .error(input, _, _):
                    SendInputTokenView(wallet: input.solanaAccount.data, isChangeEnabled: true, changeAction: {
                        // TODO: Pass here action from viewModel in https://github.com/p2p-org/p2p-wallet-ios/pull/1080
                    })
                default:
                    SendInputTokenView(wallet: Wallet(token: .eth), isChangeEnabled: true, skeleton: true, changeAction: {
                        // TODO: Pass here action from viewModel in https://github.com/p2p-org/p2p-wallet-ios/pull/1080
                    })
                }
            }
            
            VStack(spacing: 6) {
                HStack {
                    ZStack {
                        SendInputAmountField(
                            text: $viewModel.input,
                            isFirstResponder: $viewModel.isFirstResponder,
                            countAfterDecimalPoint: $viewModel.countAfterDecimalPoint,
                            textColor: .constant(.black)
                        )
                        
                        TextButtonView(
                            title: L10n.max.uppercased(),
                            style: .second,
                            size: .small
                        ) {}
                            .transition(.opacity.animation(.easeInOut))
                            .cornerRadius(radius: 32, corners: .allCorners)
                            .frame(width: 68)
                            .offset(x: true
                                ? 16.0
                                : textWidth(font: UIFont.font(of: .title2, weight: .bold), text: "1")
                            )
                            .padding(.horizontal, 8)
                            .accessibilityIdentifier("max-button")
                    }
                    .frame(height: 28)
                    
                    Text("WETH")
                        .fontWeight(.bold)
                        .apply(style: .title2)
                }
                
                HStack {
                    Text("1 215.75 USD")
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                    
                    Spacer()
                    
                    Text("WETH")
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(Asset.Colors.snow.color))
            .cornerRadius(16)
            .padding(.top, 8)
            
            Spacer()
            
            SliderActionButton(
                isSliderOn: $viewModel.isSliderOn,
                data: $viewModel.actionButtonData,
                showFinished: $viewModel.showFinished
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
 
