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
            Color(.smoke)
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
                    .foregroundColor(Color(.mountain))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 16)
            } else {
                Spacer()
                    .frame(minHeight: 16, maxHeight: 52)
            }

            HStack(spacing: 4) {
                Text(L10n.youWillSend)
                    .apply(style: .text4)
                    .foregroundColor(Color(.mountain))

                Spacer()

                Button(action: viewModel.feeInfoPressed.send) {
                    HStack(spacing: 4) {
                        Text(viewModel.feeTitle)
                            .apply(style: .text4)
                            .foregroundColor(Color(.sky))
                            .onTapGesture(perform: viewModel.feeInfoPressed.send)
                        if viewModel.isFeeLoading {
                            CircularProgressIndicatorView(
                                backgroundColor: .init(resource: .sky)
                                    .withAlphaComponent(0.6),
                                foregroundColor: .init(resource: .sky)
                            )
                            .frame(width: 16, height: 16)
                        } else {
                            Button(action: viewModel.feeInfoPressed.send, label: {
                                Image(.infoSend)
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
                Image(.warning)
                    .foregroundColor(Color(.rose))
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
        }
        .padding(EdgeInsets(top: 21, leading: 24, bottom: 21, trailing: 24))
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.snow)))
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
            ).accessibilityIdentifier("send-slider")
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

                Group {
                    Text(
                        "User limit: \(viewModel.currentState.limit.jsonString ?? "")"
                    )

                    Text(
                        "feeInSOL(networkFee: \(viewModel.currentState.fee.transaction), rentExemptionFee: \(viewModel.currentState.fee.accountBalances))"
                    )

                    Text(
                        "feeInToken(networkFee: \(viewModel.currentState.feeInToken.transaction.convertToBalance(decimals: viewModel.currentState.tokenFee.decimals)), rentExemptionFee: \(viewModel.currentState.feeInToken.accountBalances.convertToBalance(decimals: viewModel.currentState.tokenFee.decimals)))"
                    )
                }
                .font(uiFont: .font(of: .label2, weight: .regular))
                .foregroundColor(Color(.red))
                .multilineTextAlignment(.trailing)
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
                flow: .send,
                sendViaLinkSeed: nil
            )
        )
    }
}
