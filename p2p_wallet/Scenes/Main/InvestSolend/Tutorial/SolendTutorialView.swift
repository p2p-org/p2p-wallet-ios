import Combine
import KeyAppUI
import SolanaSwift
import SwiftUI

struct SolendTutorialView: View {
    @ObservedObject var viewModel: SolendTutorialViewModel
    @State private var isShowing = false

    var body: some View {
        ZStack {
            Color(Asset.Colors.lime.color)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: .zero) {
                if isShowing {
                    PagingView(
                        index: $viewModel.currentDataIndex.animation(),
                        maxIndex: viewModel.data.count - 1,
                        fillColor: Color(Asset.Colors.night.color)
                    ) {
                        ForEach(viewModel.data) { data in
                            SolendTutorialSlideView(data: data)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))

                    bottomActionsView
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

extension SolendTutorialView {
    private var bottomActionsView: some View {
        BottomActionContainer {
            VStack(spacing: .zero) {
                // Create a wallet
                TextButtonView(
                    title: L10n.createANewWallet,
                    style: .inverted,
                    size: .large,
                    trailing: Asset.MaterialIcon.arrowForward.image,
                    isEnabled: .constant(true)
                ) { [weak viewModel] in
                    viewModel?.continueDidTap.send()
                }
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
