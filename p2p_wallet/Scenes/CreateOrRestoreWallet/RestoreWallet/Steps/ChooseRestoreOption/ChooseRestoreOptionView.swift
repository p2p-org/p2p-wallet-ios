import Combine
import KeyAppUI
import SolanaSwift
import SwiftUI

struct ChooseRestoreOptionView: View {
    @ObservedObject var viewModel: ChooseRestoreOptionViewModel

    var body: some View {
        ZStack {
            Color(Asset.Colors.lime.color)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: .zero) {
                Spacer()

                OnboardingContentView(data: viewModel.data)
                    .padding(.vertical, 32)
                    .padding(.horizontal, 20)

                Spacer()

                bottomActionsView
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .onboardingNavigationBar(
            title: L10n.restoreYourWallet,
            onBack: viewModel.isBackAvailable ? { [weak viewModel] in viewModel?.back.send() } : nil,
            onInfo: { [weak viewModel] in viewModel?.openInfo.send() }
        )
    }
}

extension ChooseRestoreOptionView {
    private var bottomActionsView: some View {
        BottomActionContainer {
            VStack(spacing: viewModel.buttonsCount > 3 ? 32 : 12) {
                VStack(spacing: 12) {
                    ForEach(viewModel.mainButtons, id: \.option.rawValue) { button in
                        restoreButton(style: .inverted, content: button)
                    }
                }
                VStack(spacing: 12) {
                    ForEach(viewModel.secondaryButtons, id: \.option.rawValue) { button in
                        restoreButton(style: .outlineWhite, content: button)
                    }
                    if viewModel.isStartAvailable {
                        TextButtonView(
                            title: L10n.startingScreen,
                            style: .outlineWhite,
                            size: .large,
                            onPressed: { [weak viewModel] in
                                guard viewModel?.isLoading == nil else { return }
                                viewModel?.openStart.send()
                            }
                        )
                            .styled()
                    }
                }
            }
        }
    }
}

private extension ChooseRestoreOptionView {
    func restoreButton(
        style: TextButton.Style,
        content: ChooseRestoreOptionButton
    ) -> some View {
        TextButtonView(
            title: content.title,
            style: style,
            size: .large,
            leading: content.icon,
            isLoading: viewModel.isLoading == content.option,
            onPressed: { [weak viewModel] in
                guard viewModel?.isLoading == nil else { return }
                viewModel?.optionDidTap.send(content.option)
            }
        )
            .styled()
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
