import Combine
import KeyAppUI
import Resolver
import SolanaSwift
import SwiftUI

/// View of `CryptoAccounts` scene
struct CryptoAccountsView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: CryptoAccountsViewModel
    private let actionsPanelView: CryptoActionsPanelView
    
    @State var isHiddenSectionDisabled: Bool = true
    @State var currentUserInteractionCellID: String?
    @State var scrollAnimationIsEnded = true
    @State var isEarnBannerClosed = Defaults.isEarnBannerClosed
    
    // MARK: - Initializer
    
    init(
        viewModel: CryptoAccountsViewModel,
        actionsPanelView: CryptoActionsPanelView
    ) {
        self.viewModel = viewModel
        self.actionsPanelView = actionsPanelView
    }
    
    // MARK: - View content
    
    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.top, 11)
                        .padding(.bottom, 32)
                        .id(0)
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
    }

    private var header: some View {
        actionsPanelView
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !viewModel.transferAccounts.isEmpty {
                wrappedList(itemsCount: viewModel.transferAccounts.count) {
                    ForEach(viewModel.transferAccounts, id: \.id) {
                        tokenCell(rendableAccount: $0, isVisiable: true)
                    }
                }
            }
            wrappedList(itemsCount: viewModel.accounts.count) {
                ForEach(viewModel.accounts, id: \.id) {
                    tokenCell(rendableAccount: $0, isVisiable: true)
                }
            }
            .padding(.top, 12)
            if !viewModel.hiddenAccounts.isEmpty {
                Button(
                    action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation {
                            isHiddenSectionDisabled.toggle()
                        }
                    },
                    label: {
                        HStack(spacing: 8) {
                            Image(uiImage: isHiddenSectionDisabled ? .eyeHiddenTokens : .eyeHiddenTokensHide)
                            Text(L10n.hiddenTokens)
                                .foregroundColor(Color(Asset.Colors.mountain.color))
                                .font(.system(size: 16))
                                .padding(.vertical, 12)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                    }
                )
                if !isHiddenSectionDisabled {
                    wrappedList(itemsCount: viewModel.hiddenAccounts.count) {
                        ForEach(viewModel.hiddenAccounts, id: \.id) {
                            tokenCell(rendableAccount: $0, isVisiable: false)
                        }
                        .transition(AnyTransition.opacity.animation(.linear(duration: 0.3)))
                    }
                }
            }
        }
        .padding(.top, 16)
        .background(Color(Asset.Colors.smoke.color))
    }
    
    private func tokenCell(rendableAccount: any RenderableAccount, isVisiable: Bool) -> some View {
        CryptoAccountCellView(rendable: rendableAccount) {
            viewModel.invoke(for: rendableAccount, event: .tap)
        } onButtonTap: {
            viewModel.invoke(for: rendableAccount, event: .extraButtonTap)
        }
        .do { view in
            switch rendableAccount.extraAction {
            case .visiable:
                return AnyView(
                    view.swipeActions(
                        isVisible: isVisiable,
                        currentUserInteractionCellID: $currentUserInteractionCellID
                    ) {
                        viewModel.invoke(for: rendableAccount, event: .visibleToggle)
                    }
                )
            case .none:
                return AnyView(view)
            }
        }
        .frame(height: 72)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private func wrappedList<Content: View>(
        itemsCount: Int,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        List {
            content()
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
        }
        .listStyle(.plain)
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .frame(height: CGFloat(itemsCount) * 72)
    }
}

private extension View {
    @ViewBuilder func swipeActions(
        isVisible: Bool,
        currentUserInteractionCellID: Binding<String?>,
        action: @escaping () -> Void
    ) -> some View {
        swipeActions(allowsFullSwipe: true) {
            Button(action: action) {
                Image(uiImage: isVisible ? .eyeHide : .eyeShow)
            }
            .tint(.clear)
        }
    }

    func hideView(isVisible: Bool) -> AnyView {
        Image(uiImage: isVisible ? .eyeHide : .eyeShow)
            .animation(.default)
            .castToAnyView()
    }
}
