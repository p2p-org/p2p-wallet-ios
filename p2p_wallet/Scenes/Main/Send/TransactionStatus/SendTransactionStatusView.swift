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
            viewModel: viewModel,
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
    @ObservedObject private var viewModel: SendTransactionStatusViewModel

    @State private var isRotatingAnimation = false
    @State private var isColorTransition = true
    @State private var previousAppearance: SendTransactionStatusViewAppearance?
    @State private var currentAppearance: SendTransactionStatusViewAppearance

    private let rotationAnimation = Animation.linear(duration: 0.2).speed(0.1).repeatForever(autoreverses: false)
    private let scaleAnimation = Animation.easeInOut(duration: 0.2)
    private let errorMessageTapAction: () -> Void

    init(viewModel: SendTransactionStatusViewModel, errorMessageTapAction: @escaping () -> Void) {
        self.viewModel = viewModel
        self.currentAppearance = SendTransactionStatusViewAppearance(state: viewModel.state)
        self.previousAppearance = nil
        self.errorMessageTapAction = errorMessageTapAction
    }

    private let maxScaleEffect: CGFloat = 1.0
    private let minScaleEffect: CGFloat = 0

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                ZStack(alignment: .center) {
                    if let previousColor = previousAppearance?.circleColor {
                        Circle()
                            .fill(previousColor)
                            .frame(width: 48, height: 48)
                            .scaleEffect(maxScaleEffect)
                    }

                    if case .loading = viewModel.state {
                        Image(uiImage: .transactionStatusLoadingWrapper)
                            .resizable()
                            .frame(width: 48, height: 48)
                            .rotationEffect(.degrees(isRotatingAnimation ? 360 : 0.0))
                            .animation(isRotatingAnimation ? rotationAnimation : .default, value: isRotatingAnimation)
                            .onAppear { DispatchQueue.main.async { isRotatingAnimation = true } }
                    } else {
                        Circle()
                            .fill(currentAppearance.circleColor)
                            .frame(width: 48, height: 48)
                            .scaleEffect(isColorTransition ? maxScaleEffect : minScaleEffect)
                    }

                    Image(uiImage: currentAppearance.image)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(currentAppearance.imageColor)
                        .frame(width: currentAppearance.imageSize.width, height: currentAppearance.imageSize.height)
                }
                .padding(.leading, 5)
                Group {
                    switch viewModel.state {
                    case let .loading(message), let .succeed(message: message):
                        Text(message)
                            .messageStyled()
                    case let .error(message):
                        Text(message)
                            .messageStyled()
                            .onTapGesture(perform: errorMessageTapAction)
                    }
                }
                .padding(.leading, 2)
                Spacer()
            }
            .padding(13)
        }
        .frame(maxWidth: .infinity)
        .background(currentAppearance.backgroundColor)
        .cornerRadius(12)
        .onReceive(viewModel.$state) { value in
            previousAppearance = currentAppearance
            currentAppearance = SendTransactionStatusViewAppearance(state: value)
            isColorTransition = false
            withAnimation(scaleAnimation) { isColorTransition = true }
        }
    }
}

private extension Text {
    func messageStyled() -> some View {
        return self.apply(style: .text4)
            .foregroundColor(Color(Asset.Colors.night.color))
            .fixedSize(horizontal: false, vertical: true)
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
