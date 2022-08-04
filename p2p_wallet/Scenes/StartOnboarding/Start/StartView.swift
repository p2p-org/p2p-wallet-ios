import Combine
import KeyAppUI
import SolanaSwift
import SwiftUI

struct StartView: View {
    @ObservedObject var viewModel: StartViewModel
    @State private var isShowing = false

    var body: some View {
        ZStack {
            Color(Asset.Colors.lime.color)
                .edgesIgnoringSafeArea(.all)
            mockView
            VStack(spacing: .zero) {
                if isShowing {
                    PagingView(
                        index: $viewModel.currentDataIndex.animation(),
                        maxIndex: viewModel.data.count - 1,
                        fillColor: Color(Asset.Colors.night.color)
                    ) {
                        ForEach(viewModel.data, id: \.id) { data in
                            StartPageView(data: data, subtitleFontWeight: .medium)
                        }
                    }
                    .transition(.move(edge: .top))
                    .opacity(isShowing ? 1 : 0)

                    bottomActionsView
                        .transition(.move(edge: .bottom))
                        .opacity(isShowing ? 1 : 0)
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .onAppear {
            if viewModel.isAnimatable {
                withAnimation {
                    isShowing = true
                }
            } else {
                isShowing = true
            }
        }
    }
}

extension StartView {
    private var mockView: some View {
        VStack {
            HStack {
                Spacer()
                Button("Continue", action: viewModel.mockButtonDidTap.send)
                    .foregroundColor(Color.blue)
            }
            .padding()
            Spacer()
        }
    }

    private var bottomActionsView: some View {
        VStack(spacing: .zero) {
            // Create a wallet
            TextButtonView(
                title: L10n.createANewWallet,
                style: .inverted,
                size: .large,
                trailing: Asset.MaterialIcon.arrowForward.image
            ) { [weak viewModel] in viewModel?.createWalletDidTap.send() }
                .styled()
                .padding(.top, 20)

            // Restore a wallet
            TextButtonView(title: L10n.iAlreadyHaveAWallet, style: .ghostLime, size: .large) { [weak viewModel] in
                viewModel?.restoreWalletDidTap.send()
            }
            .styled()
            .padding(.top, 12)

            VStack(spacing: 2) {
                Text(L10n.byContinuingYouAgreeToKeyAppS)
                    .styled(color: Asset.Colors.mountain, font: .label1)
                Text(L10n.capitalizedTermsAndConditions)
                    .styled(color: Asset.Colors.snow, font: .label1)
                    .onTapGesture(perform: { [weak viewModel] in
                        viewModel?.termsDidTap.send()
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
