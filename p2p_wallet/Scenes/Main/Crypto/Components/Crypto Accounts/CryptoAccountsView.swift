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
                wrappedList(items: viewModel.transferAccounts) { data in
                    ForEach(data, id: \.id) {
                        tokenCell(rendableAccount: $0)
                    }
                }
            }

            wrappedList(items: viewModel.accounts) { data in
                ForEach(data, id: \.id) { rendableAccount in
                    tokenCell(rendableAccount: rendableAccount)
                        .swipeActions(
                            isVisible: true,
                            currentUserInteractionCellID: $currentUserInteractionCellID,
                            action: {
                                viewModel.invoke(for: rendableAccount, event: .visibleToggle)
                            }
                        )
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
                    wrappedList(items: viewModel.hiddenAccounts) { data in
                        ForEach(data, id: \.id) { rendableAccount in
                            tokenCell(rendableAccount: rendableAccount)
                                .swipeActions(
                                    isVisible: false,
                                    currentUserInteractionCellID: $currentUserInteractionCellID,
                                    action: {
                                        viewModel.invoke(for: rendableAccount, event: .visibleToggle)
                                    }
                                )
                        }
                        .transition(AnyTransition.opacity.animation(.linear(duration: 0.3)))
                    }
                }
            }
        }
        .padding(.top, 8)
        .background(Color(Asset.Colors.smoke.color))
    }

    private func tokenCell(rendableAccount: any RenderableAccount) -> some View {
        CryptoAccountCellView(rendable: rendableAccount) {
            viewModel.invoke(for: rendableAccount, event: .tap)
        } onButtonTap: {
            viewModel.invoke(for: rendableAccount, event: .extraButtonTap)
        }
        .equatable()
        .frame(height: 72)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func wrappedList(
        items: [any RenderableAccount],
        @ViewBuilder content: @escaping ([any RenderableAccount]) -> some View
    ) -> some View {
        List {
            content(items)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
        }
        .listStyle(.plain)
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .frame(height: CGFloat(items.count) * 72)
    }
}

private extension View {
    @ViewBuilder func swipeActions(
        isVisible: Bool,
        currentUserInteractionCellID _: Binding<String?>,
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
