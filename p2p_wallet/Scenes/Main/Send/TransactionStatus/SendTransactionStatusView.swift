import SwiftUI
import KeyAppUI

struct SendTransactionStatusView: View {
    @ObservedObject var viewModel: SendTransactionStatusViewModel

    init(viewModel: SendTransactionStatusViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Color(Asset.Colors.rain.color)
                .frame(width: 31, height: 4)
                .cornerRadius(2)
                .padding(.top, 6)
            title
                .padding(.top, 18)
                .padding(.bottom, 15)
            headerView
            info
                .padding(.top, 9)
                .padding(.horizontal, 18)
            status
                .padding(.horizontal, 16)
            Spacer()
            button
                .padding(.horizontal, 16)
        }
    }

    var title: some View {
        VStack(spacing: 6) {
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
                .cornerRadius(radius: 66/2, corners: .allCorners)
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
        SendTransactionStatusStatusView(state: $viewModel.state)
    }

    var button: some View {
        TextButtonView(
            title: L10n.done,
            style: .primaryWhite,
            size: .large,
            onPressed: viewModel.close.send
        )
        .frame(height: 56)
    }
}

struct SendTransactionStatusStatusView: View {
    @Binding var state: SendTransactionStatusViewModel.State
    @State private var isRotating = 0.0

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                ZStack(alignment: .center) {
                    if case .loading(_) = state {
                        Image(uiImage: .transactionStatusLoadingWrapper)
                            .rotationEffect(.degrees(isRotating))
                            .onAppear {
                                withAnimation(.linear(duration: 0.1)
                                        .speed(0.1).repeatForever(autoreverses: false)) {
                                    isRotating = 360.0
                                }
                            }
                        Image(uiImage: image)
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                            .frame(width: 24, height: 24)
                    } else if case .error(_) = state {
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
                            .foregroundColor(Color(UIColor(fromHexString: "04D004")!))
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(.leading, 5)
                Group {
                    switch state {
                    case .loading(let message), .succeed(message: let message):
                        Text(message)
                            .apply(style: .text4)
                            .foregroundColor(Color(Asset.Colors.night.color))
                    case .error(let message):
                        Text(message)
                            .apply(style: .text4)
                            .foregroundColor(Color(Asset.Colors.night.color))
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
        case .loading(_):
            return .lightningFilled
        case .error(_):
            return .solendSubtract
        case .succeed(_):
            return .lightningFilled
        }
    }

    var color: Color {
        switch state {
        case .loading(_):
            return Color(Asset.Colors.cloud.color)
        case .error(_):
            return Color(UIColor(red: 255/255, green: 220/255, blue: 233/255, alpha: 0.3))
        case .succeed(_):
            return Color(.cdf6cd).opacity(0.3)
        }
    }

}

struct SendTransactionStatusView_Previews: PreviewProvider {
    static var previews: some View {
        SendTransactionStatusView(
            viewModel: SendTransactionStatusViewModel(
                transaction: .init(
                    transactionId: "",
                    state: .zero(
                        recipient: .init(address: "", category: .solanaAddress, attributes: .funds),
                        token: .nativeSolana(pubkey: nil, lamport: nil),
                        feeToken: .nativeSolana(pubkey: nil, lamport: nil),
                        userWalletState: .empty)
                )
            )
        )
    }
}
