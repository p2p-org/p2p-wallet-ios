import Resolver
import SwiftUI

struct DetailTransactionView: View {
    @ObservedObject var viewModel: TransactionDetailViewModel

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 2, style: .circular)
                .fill(Color(.rain))
                .frame(width: 31, height: 4)
                .padding(.top, 6)

            title
                .padding(.top, 16)
                .padding(.bottom, 20)
            headerView
            info
                .padding(.top, 9)
                .padding(.horizontal, 18)
            status
            bottomActions
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
        }
        .navigationBarHidden(true)
    }

    private var title: some View {
        VStack(spacing: 4) {
            Text(viewModel.rendableTransaction.title)
                .fontWeight(.bold)
                .apply(style: .title3)
                .foregroundColor(Color(.night))
            if !viewModel.rendableTransaction.subtitle.isEmpty {
                Text(viewModel.rendableTransaction.subtitle)
                    .apply(style: .text3)
                    .foregroundColor(Color(.mountain))
            }
        }
    }

    private var amountInFiatColor: Color {
        if case .error = viewModel.rendableTransaction.status {
            return Color(.rose)
        }

        switch viewModel.rendableTransaction.amountInFiat {
        case .positive:
            return Color(.mint)
        default:
            return Color(.night)
        }
    }

    private var headerView: some View {
        VStack(alignment: .center, spacing: 0) {
            TransactionDetailIconView(icon: viewModel.rendableTransaction.icon)
                .padding(.top, 33)
            if !viewModel.rendableTransaction.amountInFiat.value.isEmpty {
                Text(viewModel.rendableTransaction.amountInFiat.value)
                    .fontWeight(.bold)
                    .apply(style: .largeTitle)
                    .foregroundColor(amountInFiatColor)
                    .padding(.top, 17)
                    .padding(.bottom, 6)
            }
            if !viewModel.rendableTransaction.amountInToken.isEmpty {
                Text(viewModel.rendableTransaction.amountInToken)
                    .apply(style: .text2)
                    .foregroundColor(Color(.mountain))
                    .padding(.top, viewModel.rendableTransaction.amountInFiat.value.isEmpty ? 16 : 0)
            }

            if !viewModel.rendableTransaction.actions.isEmpty {
                HStack(spacing: 32) {
                    ForEach(viewModel.rendableTransaction.actions) { action in
                        switch action {
                        case .share:
                            CircleButton(title: L10n.share, image: .share1) {
                                viewModel.share()
                            }
                        case .explorer:
                            CircleButton(title: L10n.explorer, image: .explorer) {
                                viewModel.explore()
                            }
                        }
                    }
                }
                .padding(.top, 28)
                .padding(.bottom, 32)
            } else {
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .padding(.bottom, 34)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(.smoke))
    }

    var info: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.rendableTransaction.extra, id: \.title) { infoItem in
                HStack(alignment: .top) {
                    Text(infoItem.title)
                        .apply(style: .text4)
                        .foregroundColor(Color(.mountain))
                    Spacer()
                    Button {
                        let clipboardManager: ClipboardManager = Resolver.resolve()
                        clipboardManager.copyToClipboard(infoItem.copyableValue ?? "")

                        let notification: NotificationService = Resolver.resolve()
                        notification.showInAppNotification(.done(L10n.theAddressWasCopiedToClipboard))
                    } label: {
                        VStack(alignment: .trailing) {
                            ForEach(infoItem.values) { value in
                                HStack {
                                    Text(value.text)
                                        .fontWeight(.bold)
                                        .apply(style: .text4)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(Color(.night))

                                    Text(value.secondaryText)
                                        .apply(style: .label1)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(Color(.night))

                                    if infoItem.copyableValue != nil {
                                        Image(.copyReceiverAddress)
                                    }
                                }
                            }
                        }
                    }.allowsHitTesting(infoItem.copyableValue != nil)
                }
                .frame(minHeight: 40)
            }
        }
    }

    var status: some View {
        if viewModel.forceHidingStatus {
            return AnyView(
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .padding(.bottom, 12)
            )
        } else if case let .succeed(message) = viewModel.rendableTransaction.status, message.isEmpty {
            return AnyView(
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .padding(.bottom, 12)
            )
        } else {
            return AnyView(
                TransactionDetailStatusView(
                    status: viewModel.rendableTransaction.status,
                    context: viewModel.statusContext
                ) {}
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
            )
        }
    }

    var bottomActions: some View {
        var style: TextButton.Style {
            switch viewModel.style {
            case .active:
                return .primaryWhite
            case .passive:
                return .second
            }
        }

        return VStack(spacing: 12) {
            ForEach(viewModel.rendableTransaction.bottomActions, id: \.id) { action in
                Button(
                    action: { buttonAction(for: action) },
                    label: {
                        Text(buttonTitle(for: action))
                            .font(uiFont: actionStyle(for: action, main: style).font(size: .large))
                            .foregroundColor(Color(actionStyle(for: action, main: style).foreground))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(actionStyle(for: action, main: style).backgroundColor))
                            .cornerRadius(12)
                    }
                )
            }
        }
    }

    func actionStyle(for type: TransactionBottomAction, main: TextButton.Style) -> TextButton.Style {
        switch type {
        case .done, .tryAgain, .increaseSlippageAndTryAgain:
            return main
        case .solscan:
            return .ghost
        }
    }

    func buttonAction(for type: TransactionBottomAction) {
        switch type {
        case .solscan:
            viewModel.explore()
        case .done, .tryAgain, .increaseSlippageAndTryAgain:
            viewModel.action.send(.close)
        }
    }

    func buttonTitle(for type: TransactionBottomAction) -> String {
        switch type {
        case .done:
            return L10n.done
        case .solscan:
            return L10n.openSOLScan
        case .tryAgain:
            return L10n.tryAgain
        case .increaseSlippageAndTryAgain:
            return L10n.increaseSlippageAndTryAgain
        }
    }
}

struct DetailTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        DetailTransactionView(
            viewModel: .init(
                rendableDetailTransaction: MockedRendableDetailTransaction.send(),
                style: .passive
            )
        )
    }
}
