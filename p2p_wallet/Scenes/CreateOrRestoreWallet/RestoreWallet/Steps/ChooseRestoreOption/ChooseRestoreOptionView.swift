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

                Spacer()

                bottomActionsView
            }
            .edgesIgnoringSafeArea(.bottom)
        }
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
                            leading: button.icon
                        ) { [weak viewModel] in viewModel?.optionChosen.send(button.option) }
                            .styled()
                    }
                }
                VStack(spacing: 12) {
                    ForEach(viewModel.secondaryButtons, id: \.option.rawValue) { button in
                        TextButtonView(
                            title: button.title,
                            style: .outlineWhite,
                            size: .large,
                            leading: button.icon
                        ) { [weak viewModel] in viewModel?.optionChosen.send(button.option) }
                            .styled()
                    }
                }
            }
        }
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
