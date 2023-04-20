//
//  SendInputView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 17.11.2022.
//

import KeyAppUI
import SwiftUI

struct SendInputView: View {
    @ObservedObject var viewModel: SendInputViewModel

    var body: some View {
        switch viewModel.loadingState {
        case .notRequested:
            Text("")
        case .loading:
            ProgressView()
        case .loaded:
            loadedView
        case let .error(error):
            VStack {
                #if !RELEASE
                    Text(error)
                        .foregroundColor(.red)
                #endif
                Text("\(L10n.somethingWentWrong). \(L10n.tapToTryAgain)?")
                    .onTapGesture {
                        Task {
                            await viewModel.load()
                        }
                    }
            }
        }
    }

    var loadedView: some View {
        ZStack(alignment: .top) {
            Color(Asset.Colors.smoke.color)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { self.viewModel.inputAmountViewModel.isFirstResponder = false }

            VStack {
                ScrollView {
                    inputView
                }
                    .padding(16)
                
                Spacer()
                
                sendButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
    }

    var inputView: some View {
        VStack(spacing: 8) {
            if viewModel.currentState.sendViaLinkSeed != nil {
                Text(L10n.anyoneWhoGetsThisOneTimeLinkCanClaimMoney)
                    .apply(style: .text3)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 16)
            } else {
                Spacer()
                    .frame(minHeight: 16, maxHeight: 52)
            }

            HStack(spacing: 4) {
                Text(L10n.youWillSend)
                    .apply(style: .text4)
                    .foregroundColor(Color(Asset.Colors.mountain.color))

                Spacer()

                Button(action: viewModel.feeInfoPressed.send) {
                    HStack(spacing: 4) {
                        Text(viewModel.feeTitle)
                            .apply(style: .text4)
                            .foregroundColor(Color(Asset.Colors.sky.color))
                            .onTapGesture(perform: viewModel.feeInfoPressed.send)
                        if viewModel.isFeeLoading {
                            CircularProgressIndicatorView(
                                backgroundColor: Asset.Colors.sky.color.withAlphaComponent(0.6),
                                foregroundColor: Asset.Colors.sky.color
                            )
                            .frame(width: 16, height: 16)
                        } else {
                            Button(action: viewModel.feeInfoPressed.send, label: {
                                Image(uiImage: UIImage.infoSend)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            })
                        }
                    }
                }
                .allowsHitTesting(!viewModel.isFeeLoading && !viewModel.lock)
                .accessibilityIdentifier("fee-label")
            }
            .padding(.horizontal, 4)

            SendInputTokenView(
                wallet: viewModel.sourceWallet,
                amountInFiat: viewModel.sourceWallet.amountInCurrentFiat,
                isChangeEnabled: viewModel.isTokenChoiceEnabled,
                changeAction: viewModel.changeTokenPressed.send
            )
            .allowsHitTesting(!viewModel.lock)
            .accessibilityIdentifier("token-view")

            switch viewModel.status {
            case .initializing:
                inputSkeletonView
            case .initializingFailed:
                initializationFailedView
            case .ready:
                SendInputAmountWrapperView(viewModel: viewModel.inputAmountViewModel)
            }

            Spacer()

            #if !RELEASE
                HStack {
                    Toggle(isOn: $viewModel.isFakeSendTransaction) {
                        Text("Fake Transaction")
                    }
                    if viewModel.isFakeSendTransaction {
                        VStack {
                            Toggle(isOn: $viewModel.isFakeSendTransactionError) {
                                Text("With Error")
                            }
                            Toggle(isOn: $viewModel.isFakeSendTransactionNetworkError) {
                                Text("With Network Error")
                            }
                        }
                    }

                    Spacer()
                }

                debugView
            #endif
        }
    }

    // TODO: Fix color
    var initializationFailedView: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(UIColor(red: 1, green: 0.863, blue: 0.914, alpha: 1)))
                    .frame(width: 48, height: 48)
                Image(uiImage: Asset.Icons.warning.image)
                    .foregroundColor(Color(Asset.Colors.rose.color))
            }
            Text("An error occurred updating the rates. Please try again 🥺")
                .apply(style: .text4)
            Spacer()
        }
        .padding(EdgeInsets(top: 21, leading: 24, bottom: 21, trailing: 12))
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(Color(UIColor(red: 1, green: 0.863, blue: 0.914, alpha: 0.3))))
        .frame(height: 90)
    }

    var inputSkeletonView: some View {
        HStack(alignment: .center) {
            VStack(spacing: 6) {
                Text("")
                    .fontWeight(.semibold)
                    .apply(style: .text2)
                    .frame(height: 28)
                    .skeleton(
                        with: true,
                        animated: .default
                    )
                Text("")
                    .fontWeight(.semibold)
                    .apply(style: .text2)
                    .skeleton(
                        with: true,
                        animated: .default
                    )
            }
            Image(uiImage: UIImage.arrowUpDown)
                .renderingMode(.template)
                .foregroundColor(Color(Asset.Colors.rain.color))
                .frame(width: 16, height: 16)
        }
        .padding(EdgeInsets(top: 21, leading: 24, bottom: 21, trailing: 12))
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(Asset.Colors.snow.color)))
        .frame(height: 90)
    }

    @ViewBuilder
    var sendButton: some View {
        switch viewModel.status {
        case .initializingFailed:
            TextButtonView(title: L10n.tryAgain, style: .primary, size: .large) {
                viewModel.initialize()
            }
            .cornerRadius(radius: 28, corners: .allCorners)
            .frame(height: TextButton.Size.large.height)
        case .initializing, .ready:
            SliderActionButton(
                isSliderOn: $viewModel.isSliderOn,
                data: viewModel.actionButtonData,
                showFinished: viewModel.showFinished
            )
            .accessibilityIdentifier("send-slider")
        }
    }

    #if !RELEASE
        var debugView: some View {
            Group {
                if viewModel.currentState.sendViaLinkSeed != nil {
                    Text("\(viewModel.getSendViaLinkURL() ?? "") (tap to copy)")
                        .apply(style: .label2)
                        .foregroundColor(.red)
                        .onTapGesture {
                            UIPasteboard.general.string = viewModel.getSendViaLinkURL()
                        }
                    Text("\(viewModel.currentState.recipient.address) (tap to copy)")
                        .apply(style: .label2)
                        .foregroundColor(.red)
                        .onTapGesture {
                            UIPasteboard.general.string = viewModel.currentState.recipient.address
                        }
                }

                FeeRelayerDebugView(
                    viewModel: .init(
                        feeInSOL: viewModel.currentState.fee,
                        feeInToken: viewModel.currentState.feeInToken,
                        payingFeeTokenDecimals: viewModel.currentState.tokenFee.decimals
                    )
                )
            }
        }
    #endif
}

struct SendInputView_Previews: PreviewProvider {
    static var previews: some View {
        SendInputView(
            viewModel: .init(
                recipient: .init(
                    address: "8JmwhgewSppZ2sDNqGZoKu3bWh8wUKZP8mdbP4M1XQx1",
                    category: .solanaAddress,
                    attributes: [.funds]
                ),
                preChosenWallet: nil,
                preChosenAmount: nil,
                source: .none,
                allowSwitchingMainAmountType: false,
                sendViaLinkSeed: nil
            )
        )
    }
}
