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
                    index: $viewModel.currentIndex.animation(),
                    maxIndex: viewModel.data.count - 1,
                    fillColor: Color(Asset.Colors.night.color)
                ) {
                    ForEach(viewModel.data, id: \.id) {
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
            TextButtonView(title: L10n.createANewWallet, style: .inverted, size: .large, trailing: UIImage.arrowForward)
                .styled()
                .padding(.top, 20)
                .onTapGesture(perform: viewModel.createWalletPressed)
            TextButtonView(title: L10n.iAlreadyHaveAWallet, style: .ghostLime, size: .large)
                .styled()
                .padding(.top, 12)
                .onTapGesture(perform: viewModel.alreadyHaveAWalletPressed)
            Group {
                Text(L10n.byContinuingYouAgreeToKeyAppS)
                    .styled(color: Asset.Colors.mountain, font: .label1) +
                    Text(L10n.capitalizedTermsAndConditions)
                    .styled(color: Asset.Colors.snow, font: .label1)
            }
            .lineLimit(.none)
            .multilineTextAlignment(.center)
            .padding(.top, 24)
            .padding(.bottom, 34)
            .onTapGesture(perform: viewModel.termsPressed)
        }
        .padding(.horizontal, 20)
        .bottomActionsStyle()
    }
}

// MARK: - Style Helpers

private extension Text {
    func styled(color: ColorAsset, font: UIFont.Style) -> Text {
        foregroundColor(Color(color.color))
            .font(.system(size: UIFont.fontSize(of: font)))
    }
}

private extension TextButtonView {
    func styled() -> some View {
        frame(height: 56)
            .frame(maxWidth: .infinity)
    }
}
