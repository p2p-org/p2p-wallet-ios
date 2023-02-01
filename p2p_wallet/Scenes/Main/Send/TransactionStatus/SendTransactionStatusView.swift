import KeyAppUI
import SwiftUI

struct SendTransactionStatusView: View {
    @ObservedObject var viewModel: SendTransactionStatusViewModel

    init(viewModel: SendTransactionStatusViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                title
                    .padding(.bottom, 20)
                headerView
                info
                    .padding(.top, 9)
                    .padding(.horizontal, 18)
                status
                    .padding(.top, 20)
                    .padding(.horizontal, 16)
                button
                    .padding(.top, 32)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            .navigationBarHidden(true)
        }
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
                size: 64,
                token: viewModel.token
            )
            .frame(width: 64, height: 64)
            .cornerRadius(radius: 64 / 2, corners: .allCorners)
            .padding(.top, 32)
            Text(viewModel.transactionFiatAmount)
                .fontWeight(.bold)
                .apply(style: .largeTitle)
                .foregroundColor(Color(Asset.Colors.night.color))
                .padding(.top, 16)
                .padding(.bottom, 4)
            if !viewModel.transactionCryptoAmount.isEmpty {
                Text(viewModel.transactionCryptoAmount)
                    .apply(style: .text2)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .padding(.bottom, 32)
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
            closeAction: viewModel.close.send,
            params: $viewModel.detailParams
        )
    }

    var button: some View {
        TextButtonView(
            title: L10n.done,
            style: .primaryWhite,
            size: .large,
            onPressed: viewModel.close.send
        )
        .frame(height: TextButton.Size.large.height)
    }
}

struct SendTransactionStatusStatusView: View {
    let state: SendTransactionStatusViewModel.State
    let closeAction: () -> Void
    @Binding var params: SendTransactionStatusDetailsParameters

    @State private var isAnimating = false
    @State private var isRotating = 0.0
    let animation: Animation = .linear(duration: 0.1).speed(0.1).repeatForever(autoreverses: false)

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                ZStack(alignment: .center) {
                    if case .loading = state {
                        Image(uiImage: .transactionStatusLoadingWrapper)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0.0))
                            .animation(isAnimating ? animation : .default, value: isAnimating)
                            .onAppear {
                                DispatchQueue.main.async { isAnimating = true }
                            }
                        Image(uiImage: image)
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .frame(width: 24, height: 24)
                    } else if case .error = state {
                        Circle()
                            .fill(color)
                            .frame(width: 48, height: 48)
                            .cornerRadius(24)
                        Image(uiImage: image)
                            .resizable()
                            .foregroundColor(Color(Asset.Colors.rose.color))
                            .frame(width: 20, height: 18)
                    } else {
                        Circle()
                            .fill(color)
                            .frame(width: 48, height: 48)
                            .cornerRadius(24)
                        Image(uiImage: image)
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color(UIColor(red: 0.016, green: 0.816, blue: 0.016, alpha: 1)))
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(.leading, 5)
                Group {
                    switch state {
                    case let .loading(message), let .succeed(message: message):
                        Text(message)
                            .apply(style: .text4)
                            .foregroundColor(Color(Asset.Colors.night.color))
                    case let .error(message):
                        NavigationLink(destination: SendTransactionStatusDetailsView(viewModel: .init(params: params, closeAction: closeAction))) {
                            Text(message)
                                .apply(style: .text4)
                                .foregroundColor(Color(Asset.Colors.night.color))
                        }
                    }
                }
                .padding(.leading, 2)
                Spacer()
            }
            .padding(13)
        }
        .frame(maxWidth: .infinity)
        .background(color)
        .cornerRadius(12)
    }

    var image: UIImage {
        switch state {
        case .loading:
            return .lightningFilled
        case .error:
            return .solendSubtract
        case .succeed:
            return .lightningFilled
        }
    }

    var color: Color {
        switch state {
        case .loading:
            return Color(Asset.Colors.cloud.color)
        case .error:
            return Color(UIColor(red: 255 / 255, green: 220 / 255, blue: 233 / 255, alpha: 0.3))
        case .succeed:
            return Color(.cdf6cd).opacity(0.3)
        }
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
