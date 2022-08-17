//
//  HomeWithTokensView.swift
//  p2p_wallet
//
//  Created by Ivan on 05.08.2022.
//

import AnalyticsManager
import BottomSheet
import KeyAppUI
import Resolver
import SolanaSwift
import SwiftUI

struct HomeWithTokensView: View {
    @Injected private var analyticsManager: AnalyticsManager

    @ObservedObject var viewModel: HomeWithTokensViewModel

    init(viewModel: HomeWithTokensViewModel) {
        self.viewModel = viewModel
        analyticsManager.log(event: .mainScreenWalletsOpen)
    }

    var body: some View {
        List {
            Group {
                header
                    .topPadding()
                    .padding(.bottom, 18)
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
    }

    private var header: some View {
        VStack(alignment: .center, spacing: 32) {
            VStack(alignment: .center, spacing: 6) {
                Text(L10n.balance)
                    .font(uiFont: .font(of: .text1, weight: .bold))
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
                .font(uiFont: .font(of: .title3, weight: .bold))
                .foregroundColor(Color(Asset.Colors.night.color))
            ForEach(viewModel.items, id: \.pubkey) {
                if $0.isNativeSOL {
                    tokenCell(isVisible: true, wallet: $0)
                } else {
                    swipeTokenCell(isVisible: true, wallet: $0)
                }
            }

            if !viewModel.hiddenItems.isEmpty {
                Button(
                    action: {
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
                        }
                    }
                )

                if !viewModel.tokensIsHidden {
                    ForEach(viewModel.hiddenItems, id: \.token.symbol) {
                        swipeTokenCell(isVisible: false, wallet: $0)
                    }
                    .transition(AnyTransition.opacity.animation(.linear(duration: 0.5)))
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
                        .font(uiFont: .font(of: .text4, weight: .bold))
                        .foregroundColor(Color(Asset.Colors.night.color))
                }
                .frame(width: 56)
            }
        )
            .buttonStyle(PlainButtonStyle())
    }

    private func tokenCell(isVisible _: Bool, wallet: Wallet) -> some View {
        TokenCellView(wallet: wallet)
            .frame(height: 72)
            .onTapGesture {
                viewModel.tokenClicked(wallet: wallet)
            }
    }

    private func swipeTokenCell(isVisible: Bool, wallet: Wallet) -> some View {
        TokenCellView(wallet: wallet)
            .swipeActions(
                trailing: [
                    SwipeActionButton(
                        icon: Image(uiImage: isVisible ? .eyeHide : .eyeShow),
                        tint: .clear,
                        action: {
                            withAnimation {
                                viewModel.toggleTokenVisibility(wallet: wallet)
                            }
                        }
                    ),
                ],
                allowsFullSwipeTrailing: true
            )
            .frame(height: 72)
            .onTapGesture {
                viewModel.tokenClicked(wallet: wallet)
            }
    }
}

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
