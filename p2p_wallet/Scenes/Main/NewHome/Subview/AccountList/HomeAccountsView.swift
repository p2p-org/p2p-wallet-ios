import Combine
import KeyAppUI
import Resolver
import SolanaSwift
import SwiftUI

struct HomeAccountsView: View {
    @ObservedObject var viewModel: HomeAccountsViewModel

    @State var isHiddenSectionDisabled: Bool = true
    @State var currentUserInteractionCellID: String?
    @State var scrollAnimationIsEnded = true

    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.top, 11)
                        .padding(.bottom, 16)
                        .id(0)
                    actionsView
                }
            }
            .customRefreshable {
                await viewModel.refresh()
            }
            .onReceive(viewModel.$scrollOnTheTop) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    scrollAnimationIsEnded = true
                }
                if scrollAnimationIsEnded {
                    withAnimation {
                        reader.scrollTo(0, anchor: .top)
                    }
                }
                scrollAnimationIsEnded = false
            }
        }
        .onAppear {
            viewModel.viewDidAppear()
        }
    }

    private var header: some View {
        ActionsPanelView(
            actions: [],
            balance: viewModel.balance,
            usdAmount: viewModel.usdcAmount,
            action: { _ in },
            balanceTapAction: viewModel.balanceTapped
        )
    }

    private var actionsView: some View {
        HomeActionsView(
            actions: viewModel.actions,
            action: {
                viewModel.actionClicked($0)
            }
        )
    }
}
