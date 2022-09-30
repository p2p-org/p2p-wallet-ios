import Combine
import KeyAppUI
import SolanaSwift
import SwiftUI

struct SolendTutorialView: View {
    @SwiftUI.Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets
    @SwiftUI.Environment(\.presentationMode) var presentationMode

    @StateObject var viewModel: SolendTutorialViewModel
    var doneHandler: (() -> Void)?

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
                            .padding(.bottom, 20)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))

                bottomActionsView
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .padding(.bottom, 20)
            }
            .edgesIgnoringSafeArea(.bottom)

            HStack {
                Spacer()
                VStack {
                    Button(L10n.skip.uppercaseFirst) {
                        markAsReadAndDismiss()
                    }
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(.system(size: UIFont.fontSize(of: .text1), weight: .medium))
                    .padding(.trailing, 20)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Actions

    private func markAsReadAndDismiss() {
        Defaults.isSolendTutorialShown = true
        presentationMode.wrappedValue.dismiss()
        doneHandler?()
    }

    // MARK: - ViewBuilders

    private var bottomActionsView: some View {
        TextButtonView(
            title: viewModel.isLastPage ? L10n.continue : L10n.next.uppercaseFirst,
            style: .primary,
            size: .large,
            isEnabled: .constant(true)
        ) { [weak viewModel] in
            if viewModel?.isLastPage == true {
                markAsReadAndDismiss()
            } else {
                withAnimation {
                    viewModel?.next()
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
