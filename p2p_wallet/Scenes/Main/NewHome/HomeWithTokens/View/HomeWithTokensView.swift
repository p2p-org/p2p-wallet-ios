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

struct HomeWithTokensView: View {
    @ObservedObject var viewModel: HomeWithTokensViewModel
    
    @State private var currentUserInteractionCellID: String?
    @State private var scrollAnimationIsEnded = true
    @State private var isEarnBannerClosed = Defaults.isEarnBannerClosed
    
    init(viewModel: HomeWithTokensViewModel) {
        self.viewModel = viewModel
    }
    
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
                await viewModel.reloadData()
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
            viewModel.viewAppeared()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.viewAppeared()
        }
    }
    
    private var header: some View {
        ActionsPanelView(
            actionsPublisher: viewModel.actions,
            balancePublisher: viewModel.balance,
            action: {
                viewModel.actionClicked($0)
            }
        )
    }

    // TODO: Sell Placeholder PWN-6246
    private var sell: some View {
        Button {
            viewModel.sellTapped()
        } label: {
            Text("Ramp Off")
        }

    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.tokens)
                .font(uiFont: .font(of: .title3, weight: .semibold))
                .foregroundColor(Color(Asset.Colors.night.color))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            wrappedList(itemsCount: viewModel.items.count) {
                ForEach(viewModel.items) {
                    swipeTokenCell(isVisible: true, wallet: $0)
                }
            }
            if !viewModel.hiddenItems.isEmpty {
                Button(
                    action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation {
                            viewModel.toggleHiddenTokensVisibility()
                        }
                    },
                    label: {
                        HStack(spacing: 8) {
                            Image(uiImage: viewModel.tokensIsHidden ? .eyeHiddenTokens : .eyeHiddenTokensHide)
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
                if !viewModel.tokensIsHidden {
                    wrappedList(itemsCount: viewModel.hiddenItems.count) {
                        ForEach(viewModel.hiddenItems) {
                            swipeTokenCell(isVisible: false, wallet: $0)
                        }
                        .transition(AnyTransition.opacity.animation(.linear(duration: 0.3)))
                    }
                }
            }
        }
    }
    
    private func tokenOperation(title: String, image: UIImage, action: @escaping () -> Void) -> some View {
        Button(
            action: action,
            label: {
                VStack(spacing: 8) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                    Text(title)
                        .font(uiFont: .font(of: .label2, weight: .semibold))
                        .foregroundColor(Color(Asset.Colors.night.color))
                }
                .frame(width: 56)
            }
        )
        .buttonStyle(PlainButtonStyle()) // prevent getting called on tapping cell
    }
    
    private func tokenCell(wallet: Wallet) -> some View {
        TokenCellView(item: TokenCellViewItem(wallet: wallet))
            .frame(height: 72)
            .padding(.horizontal, 16)
            .onTapGesture {
                viewModel.tokenClicked(wallet: wallet)
            }
    }
    
    private func swipeTokenCell(isVisible: Bool, wallet: Wallet) -> some View {
        TokenCellView(item: TokenCellViewItem(wallet: wallet))
            .swipeActions(isVisible: isVisible, currentUserInteractionCellID: $currentUserInteractionCellID, action: {
                withAnimation {
                    viewModel.toggleTokenVisibility(wallet: wallet)
                }
            })
            .frame(height: 72)
            .padding(.horizontal, 16)
            .onTapGesture {
                viewModel.tokenClicked(wallet: wallet)
            }
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
