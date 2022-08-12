import Combine
import KeyAppUI
import SolanaSwift
import SwiftUI

struct ContinueView: View {
    @ObservedObject var viewModel: ContinueViewModel

    var body: some View {
        ZStack {
            Color(Asset.Colors.lime.color)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: .zero) {
                Spacer()

                OnboardingContentView(data: viewModel.data)
                    .padding(.horizontal, 40)

                Spacer()

                bottomActionsView
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

extension ContinueView {
    private var bottomActionsView: some View {
        VStack(spacing: .zero) {
            TextButtonView(title: L10n.continue, style: .inverted, size: .large, onPressed: { [weak viewModel] in
                viewModel?.continueDidTap.send()
            })
                .styled()
                .padding(.top, 20)
            TextButtonView(title: L10n.startingScreen, style: .ghostLime, size: .large, onPressed: { [weak viewModel] in
                viewModel?.startDidTap.send()
            })
                .styled()
                .padding(.top, 12)
        }
        .bottomActionsStyle()
    }
}

// MARK: - Style Helpers

private extension TextButtonView {
    func styled() -> some View {
        frame(height: 56).frame(maxWidth: .infinity)
    }
}
