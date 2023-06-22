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
                    isMaxButtonVisible: viewModel.isMaxButtonVisible,
                    isSwitchMainAmountTypeAvailable: !viewModel.adapter.disableSwitch
                )
                .padding(.top, 8)
            }

            /// Fee
            VStack(spacing: 8) {
                HStack {
                    Button {
                        viewModel.action.send(.openFees)
                    } label: {
                        HStack(spacing: 4) {
                            Text(L10n.fee.uppercased())
                                .apply(style: .caps)
                                .foregroundColor(viewModel.adapter
                                    .isFeeGTAverage ? Color(Asset.Colors.rose.color) :
                                    Color(Asset.Colors.mountain.color))

                            Image(.warningIcon)
                                .resizable()
                                .foregroundColor(viewModel.adapter
                                    .isFeeGTAverage ? Color(Asset.Colors.rose.color) :
                                    Color(Asset.Colors.mountain.color))
                                .frame(width: 16, height: 16)
                            Spacer()
                            if viewModel.adapter.feesLoading {
                                CircularProgressIndicatorView()
                                    .frame(width: 14, height: 14)
                            } else {
                                Text(viewModel.adapter.fees)
                                    .apply(style: .text4)
                                    .foregroundColor(viewModel.adapter
                                        .isFeeGTAverage ? Color(Asset.Colors.rose.color) :
                                        Color(Asset.Colors.mountain.color))
                            }
                        }
                    }
                }
                HStack {
                    Text(L10n.totalAmount.uppercased())
                        .apply(style: .caps)
                        .foregroundColor(Color(Asset.Colors.night.color))
                    Spacer()
                    if !viewModel.adapter.feesLoading {
                        Text(
                            viewModel.inputMode == .fiat ?
                                viewModel.adapter.totalCurrencyAmount
                                : viewModel.adapter.totalCryptoAmount
                        )
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.night.color))
                    }
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)

            Spacer()

            #if DEBUG
                Button {
                    let clipboard: ClipboardManager = Resolver.resolve()
                    clipboard.copyToClipboard(String(reflecting: viewModel.state))
                } label: {
                    Text("Tap me to copy debug 😇")
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
