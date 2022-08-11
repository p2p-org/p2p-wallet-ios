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
import SwiftUI

struct HomeWithTokensView: View {
    typealias Model = HomeWithTokensViewModel.Model

    @Injected private var analyticsManager: AnalyticsManager

    @ObservedObject var viewModel: HomeWithTokensViewModel

//    @State private var tokenDetailIsPresented = false

    init(viewModel: HomeWithTokensViewModel) {
        self.viewModel = viewModel
        analyticsManager.log(event: .mainScreenWalletsOpen)
    }

    var body: some View {
        RefreshableScrollView(
            refreshing: $viewModel.pullToRefreshPending,
            onTop: $viewModel.scrollOnTheTop,
            action: { viewModel.reloadData() },
            content: { scrollingContent }
        )
//            .bottomSheet(isPresented: $tokenDetailIsPresented, height: 700) {
//                TokenDetailActionView()
//            }
    }

    var scrollingContent: some View {
        VStack(alignment: .center, spacing: 32) {
            VStack(alignment: .center, spacing: 6) {
                Text(L10n.balance)
                    .font(uiFont: .font(of: .text1, weight: .bold))
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                Text(viewModel.balance)
                    .font(uiFont: .font(of: .title1, weight: .bold))
                    .foregroundColor(Color(Asset.Colors.night.color))
            }
            tokenOperationsButtons
            tokens
        }
        .padding(.vertical, 16)
    }

    var tokenOperationsButtons: some View {
        HStack(spacing: 37) {
            tokenOperation(title: L10n.buy, image: .homeBuy) {
                viewModel.buy()
            }
            tokenOperation(title: L10n.receive, image: .homeReceive) {
                viewModel.receive()
            }
            tokenOperation(title: L10n.send, image: .homeSend) {
                viewModel.send()
            }
            tokenOperation(title: L10n.trade, image: .homeSwap) {
                viewModel.trade()
            }
        }
    }

    func tokenOperation(title: String, image: UIImage, action: @escaping () -> Void) -> some View {
        Button(
            action: action,
            label: {
                VStack(spacing: 8) {
                    Image(uiImage: image)
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(Asset.Colors.night.color))
                }
            }
        )
    }

    var tokens: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tokens)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(Asset.Colors.night.color))
                .padding(.horizontal, 16)
            ForEach(viewModel.items, id: \.title) {
                tokenCell(isVisible: true, model: $0)
            }
            if !viewModel.hiddenItems.isEmpty {
                Button(
                    action: {
                        viewModel.toggleHiddenTokensVisibility()
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
                    .padding(.horizontal, 16)
                if !viewModel.tokensIsHidden {
                    ForEach(viewModel.hiddenItems, id: \.title) {
                        tokenCell(isVisible: false, model: $0)
                    }
                    .transition(AnyTransition.opacity.animation(.linear(duration: 0.5)))
                }
            }
        }
    }

    private func tokenCell(isVisible: Bool, model: Model) -> some View {
        TokenCellView(model: model)
            .padding(.horizontal, 16)
            .swipeActions(
                trailing: [
                    SwipeActionButton(
                        icon: Image(uiImage: isVisible ? .eyeHide : .eyeShow),
                        tint: .clear,
                        action: {
                            viewModel.toggleTokenVisibility(model: model)
                        }
                    ),
                ],
                allowsFullSwipeTrailing: true
            )
            .frame(height: 72)
            .onTapGesture {
//                tokenDetailIsPresented.toggle()
                viewModel.tokenClicked(model: model)
            }
    }
}
