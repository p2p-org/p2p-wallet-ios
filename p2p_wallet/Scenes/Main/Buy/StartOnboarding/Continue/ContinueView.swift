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
                Spacer()

                bottomActionsView
            }.edgesIgnoringSafeArea(.bottom)
        }
    }
}

extension ContinueView {
    private var bottomActionsView: some View {
        BottomActionContainer {
            VStack(spacing: .zero) {
                NewTextButton(
                    title: L10n.continue,
                    style: .inverted
                ) { [weak viewModel] in
                    viewModel?.continueDidTap.send()
                }

                NewTextButton(
                    title: L10n.startingScreen,
                    style: .ghostLime
                ) { [weak viewModel] in
                    viewModel?.startDidTap.send()
                }
                .padding(.top, 12)
            }
        }
    }
}
