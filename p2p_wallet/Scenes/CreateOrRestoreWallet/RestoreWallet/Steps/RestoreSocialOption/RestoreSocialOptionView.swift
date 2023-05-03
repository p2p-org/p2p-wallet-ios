import Combine
import KeyAppUI
import SwiftUI

struct RestoreSocialOptionView: View {
    @ObservedObject var viewModel: RestoreSocialOptionViewModel

    var body: some View {
        VStack(spacing: 12) {
            NewTextButton(
                title: L10n.continueWithApple,
                style: .inverted,
                isLoading: viewModel.isLoading == .apple,
                leading: .appleLogo
            ) { [weak viewModel] in
                guard viewModel?.isLoading == nil else { return }
                viewModel?.optionDidTap.send(.apple)
            }

            NewTextButton(
                title: L10n.continueWithGoogle,
                style: .inverted,
                isLoading: viewModel.isLoading == .google,
                leading: .google
            ) { [weak viewModel] in
                guard viewModel?.isLoading == nil else { return }
                viewModel?.optionDidTap.send(.google)
            }
        }
    }
}
