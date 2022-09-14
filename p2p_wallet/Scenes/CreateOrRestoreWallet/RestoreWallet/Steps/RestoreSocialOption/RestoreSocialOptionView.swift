import Combine
import KeyAppUI
import SwiftUI

struct RestoreSocialOptionView: View {
    @ObservedObject var viewModel: RestoreSocialOptionViewModel

    var body: some View {
        VStack(spacing: 12) {
            TextButtonView(
                title: L10n.continueWithApple,
                style: .inverted,
                size: .large,
                leading: .appleLogo,
                isLoading: viewModel.isLoading == .apple
            ) { [weak viewModel] in
                guard viewModel.isLoading == nil else { return }
                viewModel?.optionDidTap.send(.apple)
            }
                .styled()
            TextButtonView(
                title: L10n.continueWithGoogle,
                style: .inverted,
                size: .large,
                leading: .google,
                isLoading: viewModel.isLoading == .google
            ) { [weak viewModel] in
                guard viewModel.isLoading == nil else { return }
                viewModel?.optionDidTap.send(.google)
            }
                .styled()
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
