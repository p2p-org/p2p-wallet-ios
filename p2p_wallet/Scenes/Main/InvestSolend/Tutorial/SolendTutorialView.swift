import Combine
import KeyAppUI
import SolanaSwift
import SwiftUI

struct SolendTutorialView: View {
    @SwiftUI.Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets
    @StateObject var viewModel: SolendTutorialViewModel

    var body: some View {
        ZStack {
            Color(.e0dbff)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: .zero) {
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
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

extension SolendTutorialView {
    private var bottomActionsView: some View {
        TextButtonView(
            title: viewModel.isLastPage ? L10n.continue: L10n.next.uppercaseFirst,
            style: .primary,
            size: .large,
            isEnabled: .constant(true)
        ) { [weak viewModel] in
            if viewModel?.isLastPage == true {
                withAnimation {
//                    viewModel?.continueDidTap.send()
                }
            } else {
                withAnimation {
                    viewModel?.goNext()
                }
            }
        }
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, max(safeAreaInsets.bottom, 20))
    }
}
