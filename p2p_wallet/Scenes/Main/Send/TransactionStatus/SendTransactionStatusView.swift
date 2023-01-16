import KeyAppUI
import SwiftUI

struct SendTransactionStatusView: View {
    @ObservedObject var viewModel: SendTransactionStatusViewModel

    init(viewModel: SendTransactionStatusViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            title
                .padding(.top, 16)
                .padding(.bottom, 20)
            headerView
            info
                .padding(.top, 9)
                .padding(.horizontal, 18)
            status
                .padding(.horizontal, 16)
            Spacer()
            button
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
        }
        .navigationBarHidden(true)
    }

    var title: some View {
        VStack(spacing: 4) {
            Text(viewModel.title)
                .fontWeight(.bold)
                .apply(style: .title3)
                .foregroundColor(Color(Asset.Colors.night.color))
            if !viewModel.subtitle.isEmpty {
                Text(viewModel.subtitle)
                    .apply(style: .text3)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .center, spacing: 0) {
            CoinLogoImageViewRepresentable(
                size: 66,
                token: viewModel.token
            )
            .frame(width: 66, height: 66)
            .cornerRadius(radius: 66 / 2, corners: .allCorners)
            .padding(.top, 33)
            Text(viewModel.transactionFiatAmount)
                .fontWeight(.bold)
                .apply(style: .largeTitle)
                .foregroundColor(Color(Asset.Colors.night.color))
                .padding(.top, 17)
                .padding(.bottom, 6)
            if !viewModel.transactionCryptoAmount.isEmpty {
                Text(viewModel.transactionCryptoAmount)
                    .apply(style: .text2)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .padding(.bottom, 34)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(Asset.Colors.smoke.color))
    }

    var info: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.info, id: \.title) { infoItem in
                HStack {
                    Text(infoItem.title)
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                    Spacer()
                    Text(infoItem.detail)
                        .fontWeight(.bold)
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.night.color))
                }
                .frame(minHeight: 40)
            }
        }
    }

    var status: some View {
        SendTransactionStatusStatusView(
            state: viewModel.state,
            errorMessageTapAction: { [weak viewModel] in viewModel?.errorMessageTap.send() }
        )
    }

    var button: some View {
        TextButtonView(
            title: viewModel.closeButtonTitle,
            style: .primaryWhite,
            size: .large,
            onPressed: viewModel.close.send
        )
        .frame(height: 56)
    }
}

struct SendTransactionStatusStatusView: View {
    let state: SendTransactionStatusViewModel.State
    let errorMessageTapAction: () -> Void
    let appearance: SendTransactionStatusViewAppearance

    @State private var isAnimating = false
    @State private var isRotating = 0.0
    let animation: Animation = .linear(duration: 0.2).speed(0.1).repeatForever(autoreverses: false)

    init(state: SendTransactionStatusViewModel.State, errorMessageTapAction: @escaping () -> Void) {
        self.state = state
        self.errorMessageTapAction = errorMessageTapAction
        self.appearance = SendTransactionStatusViewAppearance(state: state)
    }

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                ZStack(alignment: .center) {
                    switch state {
                    case .loading:
                        Image(uiImage: .transactionStatusLoadingWrapper)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0.0))
                            .animation(isAnimating ? animation : .default, value: isAnimating)
                            .onAppear {
                                DispatchQueue.main.async { isAnimating = true }
                            }
                    default:
                        Circle()
                            .fill(appearance.circleColor)
                            .frame(width: 48, height: 48)
                            .cornerRadius(24)
                    }
                    Image(uiImage: appearance.image)
                        .renderingMode(.template)
                        .resizable()
                        .foregroundColor(appearance.imageColor)
                        .frame(width: appearance.imageSize.width, height: appearance.imageSize.height)
                }
                .padding(.leading, 5)
                Group {
                    switch state {
                    case let .loading(message), let .succeed(message: message):
                        Text(message)
                            .apply(style: .text4)
                            .foregroundColor(Color(Asset.Colors.night.color))
                    case let .error(message):
                        Text(message)
                            .apply(style: .text4)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .onTapGesture(perform: errorMessageTapAction)
                    }
                }
                .padding(.leading, 2)
                Spacer()
            }
            .padding(13)
        }
        .frame(maxWidth: .infinity)
        .background(appearance.backgroundColor)
        .cornerRadius(12)
    }
}

struct SendTransactionStatusView_Previews: PreviewProvider {
    static var previews: some View {
        SendTransactionStatusView(
            viewModel: SendTransactionStatusViewModel(
                transaction: .init(
                    state: .zero(
                        recipient: .init(address: "", category: .solanaAddress, attributes: .funds),
                        token: .nativeSolana,
                        feeToken: .nativeSolana,
                        userWalletState: .empty
                    )
                ) { "0123abc" }
            )
        )
    }
}
