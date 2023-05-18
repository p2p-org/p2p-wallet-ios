//
//  HomeWithTokensView.swift
//  p2p_wallet
//
//  Created by Ivan on 05.08.2022.
//

import Combine
import KeyAppUI
import Resolver
import SolanaSwift
import SwiftUI
import KeyAppKitCore

struct HomeAccountsView: View {
    @ObservedObject var viewModel: HomeAccountsViewModel

    @State var isHiddenSectionDisabled: Bool = true
    @State var currentUserInteractionCellID: String?
    @State var scrollAnimationIsEnded = true
    @State var isEarnBannerClosed = Defaults.isEarnBannerClosed

    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                VStack(spacing: 0) {
                    header
                        .topPadding()
                        .padding(.bottom, 32)
                        .id(0)
                    content
                }
            }
            .customRefreshable {
                do {
                    await viewModel.refresh()
                } catch {
                    Resolver.resolve(ErrorObserver.self).handleError(error)
                }
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
        ActionsPanelView(
            actions: viewModel.actions,
            balance: viewModel.balance,
            usdAmount: "",
            action: {
                viewModel.actionClicked($0)
            }
        )
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.tokens)
                .font(uiFont: .font(of: .title3, weight: .semibold))
                .foregroundColor(Color(Asset.Colors.night.color))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            wrappedList(itemsCount: viewModel.accounts.count) {
                ForEach(viewModel.accounts, id: \.id) {
                    tokenCell(rendableAccount: $0, isVisiable: true)
                }
            }
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
    }

    private func tokenCell(rendableAccount: any RenderableAccount, isVisiable: Bool) -> some View {
        HomeAccountView(rendable: rendableAccount) {
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
        if #available(iOS 15, *) {
            List {
                content()
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            }
            .listStyle(.plain)
            .frame(height: CGFloat(itemsCount) * 72)
        } else {
            LazyVStack(spacing: 0) {
                content()
            }
        }
    }
}

private extension View {
    @ViewBuilder func swipeActions(
        isVisible: Bool,
        currentUserInteractionCellID: Binding<String?>,
        action: @escaping () -> Void
    ) -> some View {
        if #available(iOS 15, *) {
            swipeActions(allowsFullSwipe: true) {
                Button(action: action) {
                    Image(uiImage: isVisible ? .eyeHide : .eyeShow)
                }
                .tint(.clear)
            }
        } else {
            swipeCell(
                cellWidth: UIScreen.main.bounds.width - 16 * 2,
                trailingSideGroup: [
                    SwipeCellActionItem(
                        buttonView: {
                            hideView(isVisible: isVisible)
                        },
                        swipeOutButtonView: {
                            hideView(isVisible: isVisible)
                        },
                        buttonWidth: 85,
                        backgroundColor: .clear,
                        swipeOutAction: true,
                        swipeOutHapticFeedbackType: .success,
                        swipeOutIsDestructive: false,
                        actionCallback: action
                    ),
                ],
                currentUserInteractionCellID: currentUserInteractionCellID
            )
        }
    }

    func hideView(isVisible: Bool) -> AnyView {
        Image(uiImage: isVisible ? .eyeHide : .eyeShow)
            .animation(.default)
            .castToAnyView()
    }

    @ViewBuilder
    func topPadding() -> some View {
        if #available(iOS 15, *) {
            padding(.top, 11)
        } else {
            self
        }
    }
}
