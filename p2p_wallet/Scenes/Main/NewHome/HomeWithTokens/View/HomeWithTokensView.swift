//
//  HomeWithTokensView.swift
//  p2p_wallet
//
//  Created by Ivan on 05.08.2022.
//

import AnalyticsManager
import KeyAppUI
import Resolver
import SolanaSwift
import SwiftUI

struct HomeWithTokensView: View {
    @Injected private var analyticsManager: AnalyticsManager

    @ObservedObject var viewModel: HomeWithTokensViewModel

    @State private var currentUserInteractionCellID: String?
    @State private var scrollAnimationIsEnded = true

    init(viewModel: HomeWithTokensViewModel) {
        self.viewModel = viewModel
        analyticsManager.log(event: AmplitudeEvent.mainScreenWalletsOpen)
        UITableView.appearance().showsVerticalScrollIndicator = false
    }

    var body: some View {
        ScrollViewReader { reader in
            List {
                Group {
                    header
                        .topPadding()
                        .padding(.bottom, 18)
                        .id(0)
                    content
                }
                .horizontalPadding()
                .withoutSeparatorsAfterListContent()
            }
            .withoutSeparatorsiOS14()
            .listStyle(.plain)
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
    }

    private var header: some View {
        VStack(alignment: .center, spacing: 32) {
            VStack(alignment: .center, spacing: 6) {
                Text(L10n.balance)
                    .font(uiFont: .font(of: .text1, weight: .semibold))
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                Text(viewModel.balance)
                    .font(uiFont: .font(of: .title1, weight: .bold))
                    .foregroundColor(Color(Asset.Colors.night.color))
            }
            HStack {
                tokenOperation(title: L10n.buy, image: .homeBuy) {
                    viewModel.buy()
                }
                Spacer()
                tokenOperation(title: L10n.receive, image: .homeReceive) {
                    viewModel.receive()
                }
                Spacer()
                tokenOperation(title: L10n.send, image: .homeSend) {
                    viewModel.send()
                }
                Spacer()
                tokenOperation(title: L10n.trade, image: .homeSwap) {
                    viewModel.trade()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var content: some View {
        Group {
            Text(L10n.tokens)
                .font(uiFont: .font(of: .title3, weight: .semibold))
                .foregroundColor(Color(Asset.Colors.night.color))
            ForEach(viewModel.items, id: \.pubkey) {
                if $0.isNativeSOL {
                    tokenCell(wallet: $0)
                } else {
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
//                        withAnimation {
//                            viewModel.toggleHiddenTokensVisibility()
//                        }
                    },
                    label: {
                        HStack(spacing: 8) {
                            Image(uiImage: viewModel.tokensIsHidden ? .eyeHiddenTokens : .eyeHiddenTokensHide)
                            Text(L10n.hiddenTokens)
                                .foregroundColor(Color(Asset.Colors.mountain.color))
                                .font(.system(size: 16))
                        }
                    }
                )

                if !viewModel.tokensIsHidden {
                    ForEach(viewModel.hiddenItems, id: \.token.symbol) {
                        swipeTokenCell(isVisible: false, wallet: $0)
                    }
                    .transition(AnyTransition.opacity.animation(.linear(duration: 0.3)))
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
                        .font(uiFont: .font(of: .text4, weight: .semibold))
                        .foregroundColor(Color(Asset.Colors.night.color))
                }
                .frame(width: 56)
            }
        )
            .buttonStyle(PlainButtonStyle())
    }

    private func tokenCell(wallet: Wallet) -> some View {
        TokenCellView(item: TokenCellViewItem(wallet: wallet))
            .frame(height: 72)
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
            .onTapGesture {
                viewModel.tokenClicked(wallet: wallet)
            }
    }
}

// MARK: - Swipe Actions

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
}

// MARK: - Paddings

private extension View {
    @ViewBuilder func horizontalPadding() -> some View {
        if #available(iOS 15, *) {
            padding(.horizontal, 16)
        } else {
            self
        }
    }

    @ViewBuilder func topPadding() -> some View {
        if #available(iOS 15, *) {
            padding(.top, 16)
        } else {
            self
        }
    }
}
