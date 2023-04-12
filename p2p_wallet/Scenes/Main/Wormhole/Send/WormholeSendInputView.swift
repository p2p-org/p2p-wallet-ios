//
//  WormholeSendView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.03.2023.
//

import KeyAppKitCore
import KeyAppUI
import Kingfisher
import Resolver
import SolanaSwift
import SwiftUI

struct WormholeSendInputView: View {
    @ObservedObject var viewModel: WormholeSendInputViewModel

    let inputFount = UIFont.font(of: .title2, weight: .bold)
    @State private var switchAreaOpacity: Double = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            VStack(alignment: .leading, spacing: 12) {
                Text(RecipientFormatter.format(destination: viewModel.recipient.address))
                    .fontWeight(.bold)
                    .apply(style: .largeTitle)

                Text(L10n.wouldBeCompletedOnTheEthereumNetwork)
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
                            } else if !viewModel.adapter.fees.isEmpty {
                                Image(uiImage: UIImage.infoSend)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)

                // Account view
                SendInputTokenView(
                    wallet: viewModel.adapter.inputAccount?.data ?? Wallet(token: .eth),
                    amountInFiat: viewModel.adapter.inputAccount?.amountInFiatDouble ?? 0.0,
                    isChangeEnabled: true,
                    skeleton: viewModel.adapter.inputAccountSkeleton
                ) {
                    viewModel.action.send(.openPickAccount)
                    viewModel.changeTokenPressed.send()
                }
            }

            if let account = viewModel.adapter.inputAccount {
                // Amount view
                SendInputAmountView(
                    amountText: $viewModel.input,
                    isFirstResponder: $viewModel.isFirstResponder,
                    amountTextColor: viewModel.adapter.inputColor,
                    countAfterDecimalPoint: viewModel.countAfterDecimalPoint,
                    mainTokenText: viewModel.inputMode == .crypto ? account.data.token.symbol : viewModel.adapter
                        .fiatString,
                    secondaryAmountText: viewModel.secondaryAmountString,
                    secondaryCurrencyText: viewModel.inputMode == .crypto ? viewModel.adapter.fiatString : account.data
                        .token.symbol,
                    maxAmountPressed: viewModel.maxPressed,
                    switchPressed: viewModel.switchPressed,
                    isMaxButtonVisible: viewModel.input.isEmpty,
                    isSwitchMainAmountTypeAvailable: !viewModel.adapter.disableSwitch
                )
                .padding(.top, 8)
            }

            Spacer()

            #if DEBUG
                Button {
                    let clipboard: ClipboardManager = Resolver.resolve()
                    if let transaction = viewModel.adapter.output?.transactions {
                        do {
                            clipboard.copyToClipboard(transaction.transaction)
                        } catch {
                            print(error)
                        }
                    }
                } label: {
                    Text("Tap me to copy transaction 😇")
                }
            #endif

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

private extension Text {
    func secondaryStyle() -> some View {
        foregroundColor(Color(Asset.Colors.mountain.color)).apply(style: .text4).lineLimit(1)
    }
}
