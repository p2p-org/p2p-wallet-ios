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
            title: L10n.restoringYourWallet,
            onBack: viewModel.isBackAvailable ? { [weak viewModel] in viewModel?.back.send() } : nil,
            onInfo: { [weak viewModel] in viewModel?.openInfo.send() }
        )
    }
}

extension ChooseRestoreOptionView {
    private var bottomActionsView: some View {
        BottomActionContainer {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    ForEach(viewModel.mainButtons, id: \.option.rawValue) { button in
                        TextButtonView(
                            title: button.title,
                            style: .inverted,
                            size: .large,
                            leading: button.icon,
                            isLoading: viewModel.isLoading == button.option
                        ) { [weak viewModel] in viewModel?.optionDidTap.send(button.option) }
                            .styled()
                    }
                }
                VStack(spacing: 12) {
                    ForEach(viewModel.secondaryButtons, id: \.option.rawValue) { button in
                        secondaryButton(
                            title: button.title,
                            icon: button.icon,
                            isLoading: viewModel.isLoading == button.option
                        ) { [weak viewModel] in
                            viewModel?.optionDidTap.send(button.option)
                        }
                    }
                    if viewModel.isStartAvailable {
                        secondaryButton(title: L10n.goToTheStartingScreen) { [weak viewModel] in
                            viewModel?.openStart.send()
                        }
                    }
                }
            }
        }
    }
}

private extension ChooseRestoreOptionView {
    func secondaryButton(title: String, icon: UIImage? = nil, isLoading: Bool = false,
                         onPressed: @escaping () -> Void) -> some View
    {
        TextButtonView(
            title: title,
            style: .outlineWhite,
            size: .large,
            leading: icon,
            isLoading: isLoading,
            onPressed: onPressed
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
