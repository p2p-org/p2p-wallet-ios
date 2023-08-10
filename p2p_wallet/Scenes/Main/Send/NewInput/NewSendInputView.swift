import KeyAppUI
import SwiftUI

struct NSendInputView: View {
    @ObservedObject var viewModel: NSendInputViewModel

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
            HStack(spacing: 4) {
                Text(L10n.youWillSend)
                    .apply(style: .text4)
                    .foregroundColor(Color(Asset.Colors.mountain.color))

                Spacer()

                Button(action: viewModel.feeInfoPressed.send) {
                    HStack(spacing: 4) {
                        Text(viewModel.fee.title)
                            .apply(style: .text4)
                            .foregroundColor(Color(Asset.Colors.sky.color))
                            .onTapGesture(perform: viewModel.feeInfoPressed.send)
                        if viewModel.fee.loading {
                            NewCircularProgressIndicator(
                                backgroundColor: Color(Asset.Colors.sky.color.withAlphaComponent(0.6)),
                                foregroundColor: Color(Asset.Colors.sky.color)
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
                .allowsHitTesting(!viewModel.fee.loading)
                .accessibilityIdentifier("fee-label")
            }
            .padding(.horizontal, 4)

            if let input = viewModel.currentState.input {
                SendInputTokenView(
                    wallet: input.account,
                    amountInFiat: input.account.amountInCurrentFiat,
                    isChangeEnabled: viewModel.allowSwitchAccount,
                    changeAction: viewModel.changeTokenPressed.send
                )
                .accessibilityIdentifier("token-view")
            } else {
                inputSkeletonView
            }

            switch viewModel.status {
            case .initializing:
                inputSkeletonView
            case .initializingFailed:
                initializationFailedView
            case .ready:
                SendInputAmountWrapperView(viewModel: viewModel.inputAmountViewModel)
            }
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
            ).accessibilityIdentifier("send-slider")
        }
    }
}

struct NSendInputView_Previews: PreviewProvider {
    static var previews: some View {
        NSendInputView(
            viewModel: .init(
                recipient: .init(
                    address: "8JmwhgewSppZ2sDNqGZoKu3bWh8wUKZP8mdbP4M1XQx1",
                    category: .solanaAddress,
                    attributes: [.funds]
                ),
                account: nil,
                allowSwitchAccount: false
            )
        )
    }
}
