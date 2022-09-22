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
                    if viewModel.data.count == 1, let content = viewModel.data.first {
                        Spacer()
                        OnboardingContentView(data: content)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .padding(.bottom, 32)
                        Spacer()
                    } else {
                        PagingView(
                            index: $viewModel.currentDataIndex.animation(),
                            maxIndex: viewModel.data.count - 1,
                            fillColor: Color(Asset.Colors.night.color)
                        ) {
                            ForEach(viewModel.data, id: \.id) { data in
                                OnboardingContentView(data: data)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

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

                OnboardingTermAndConditionButton(
                    onPressed: { [weak viewModel] in
                        viewModel?.termsDidTap.send()
                    },
                    isStart: true
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
