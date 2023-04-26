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
            VStack(spacing: .zero) {
                if isShowing {
                    PagingView(
                        fillColor: Color(Asset.Colors.night.color),
                        content: viewModel.data.map { data in
                            PageContent {
                                VStack {
                                    Spacer()
                                    OnboardingContentView(data: data)
                                }
                            }
                        }
                    )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .padding(.bottom, 32)
                        .padding(.top, 60)

                    bottomActionsView
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
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
    private var bottomActionsView: some View {
        BottomActionContainer {
            VStack(spacing: .zero) {
                // Create a wallet
                TextButtonView(
                    title: L10n.createANewWallet,
                    style: .inverted,
                    size: .large,
                    trailing: Asset.MaterialIcon.arrowForward.image
                ) { [weak viewModel] in viewModel?.createWalletDidTap.send() }
                    .styled()

                // Restore a wallet
                TextButtonView(title: L10n.iAlreadyHaveAWallet, style: .ghostLime, size: .large) { [weak viewModel] in
                    viewModel?.restoreWalletDidTap.send()
                }
                .styled()
                .padding(.top, 12)

                OnboardingTermsAndPolicyButton(
                    termsPressed: { [weak viewModel] in
                        viewModel?.termsDidTap.send()
                    },
                    privacyPolicyPressed: { [weak viewModel] in
                        viewModel?.privacyPolicyDidTap.send()
                    },
                    termsText: L10n.byContinuingYouAgreeToKeyAppS
                ).padding(.top, 24)
            }
        }
    }
}

// MARK: - Style Helpers

private extension TextButtonView {
    func styled() -> some View {
        frame(height: 56)
            .frame(maxWidth: .infinity)
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView(viewModel: StartViewModel(isAnimatable: false))
    }
}
