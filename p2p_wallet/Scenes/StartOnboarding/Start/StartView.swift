import Combine
import KeyAppUI
import SolanaSwift
import SwiftUI

struct StartView: View {
    @ObservedObject var viewModel: StartViewModel

    var body: some View {
        ZStack {
            Color(Asset.Colors.lime.color)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: .zero) {
                PagingView(
                    index: $viewModel.input.currentDataIndex.value.animation(),
                    maxIndex: viewModel.output.data.value.count - 1,
                    fillColor: Color(Asset.Colors.night.color)
                ) {
                    ForEach(viewModel.output.data.value, id: \.id) {
                        StartPageView(data: $0, subtitleFontWeight: .medium)
                    }
                }

                bottomActionsView
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

extension StartView {
    private var bottomActionsView: some View {
        VStack(spacing: .zero) {
            // Create a wallet
            TextButtonView(
                title: L10n.createANewWallet,
                style: .inverted,
                size: .large,
                trailing: UIImage.arrowForward
            ) { [weak viewModel] in viewModel?.input.createWalletDidTap.send() }
                .styled()
                .padding(.top, 20)

            // Restore a wallet
            TextButtonView(title: L10n.iAlreadyHaveAWallet, style: .ghostLime, size: .large) { [weak viewModel] in
                viewModel?.input.restoreWalletDidTap.send()
            }
            .styled()
            .padding(.top, 12)

            VStack(spacing: 2) {
                Text(L10n.byContinuingYouAgreeToKeyAppS)
                    .styled(color: Asset.Colors.mountain, font: .label1)
                Text(L10n.capitalizedTermsAndConditions)
                    .styled(color: Asset.Colors.snow, font: .label1)
                    .onTapGesture(perform: { [weak viewModel] in
                        viewModel?.input.openTermsDidTap.send()
                    })
            }
            .padding(.vertical, 24)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .bottomActionsStyle()
    }
}

// MARK: - Style Helpers

private extension Text {
    func styled(color: ColorAsset, font: UIFont.Style) -> some View {
        foregroundColor(Color(color.color))
            .font(.system(size: UIFont.fontSize(of: font)))
            .lineLimit(.none)
            .multilineTextAlignment(.center)
    }
}

private extension TextButtonView {
    func styled() -> some View {
        frame(height: 56)
            .frame(maxWidth: .infinity)
    }
}
