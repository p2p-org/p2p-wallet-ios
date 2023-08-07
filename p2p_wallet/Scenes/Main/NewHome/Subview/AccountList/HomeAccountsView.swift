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
                    content
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

    private var accounts: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(viewModel.accounts, id: \.id) { acc in
                bankTransferCell(rendableAccount: acc, isVisible: true)
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    .frame(height: 72)
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let smallBanner = viewModel.smallBanner {
                HomeSmallBannerView(params: smallBanner)
                    .animation(.linear, value: smallBanner)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .onChange(of: viewModel.shouldCloseBanner) { [weak viewModel] output in
                        guard output else { return }
                        withAnimation { viewModel?.closeBanner(id: smallBanner.id) }
                    }
                    .onTapGesture(perform: viewModel.bannerTapped.send)
            }
            if !viewModel.accounts.isEmpty {
                accounts
                    .padding(.top, 48)
            }
            Spacer()
        }
    }

    private func bankTransferCell(
        rendableAccount: any RenderableAccount,
        isVisible _: Bool
    ) -> some View {
        HomeBankTransferAccountView(
            renderable: rendableAccount,
            onTap: { viewModel.invoke(for: rendableAccount, event: .tap) },
            onButtonTap: { viewModel.invoke(for: rendableAccount, event: .extraButtonTap) }
        )
    }
}
