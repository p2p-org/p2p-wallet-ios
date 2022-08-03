import KeyAppUI
import SwiftUI

struct ProtectionLevelView: View {
    @ObservedObject var viewModel: ProtectionLevelViewModel

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

extension ProtectionLevelView {
    private var bottomActionsView: some View {
        VStack(spacing: .zero) {
            TextButtonView(
                title: viewModel.bioAuthButtonTitle,
                style: .inverted,
                size: .large,
                trailing: .faceId,
                onPressed: { [weak viewModel] in
                    viewModel?.useFaceIdDidTap.send()
                }
            )
                .styled()
                .padding(.top, 20)
            TextButtonView(title: L10n.setUpAPINCode, style: .ghostLime, size: .large, onPressed: { [weak viewModel] in
                viewModel?.setUpPinDidTap.send()
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
