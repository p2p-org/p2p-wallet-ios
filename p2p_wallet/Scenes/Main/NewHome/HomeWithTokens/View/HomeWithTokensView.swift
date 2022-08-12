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

//    @State private var tokenDetailIsPresented = false

    init(viewModel: HomeWithTokensViewModel) {
        self.viewModel = viewModel
        analyticsManager.log(event: .mainScreenWalletsOpen)

        if #unavailable(iOS 15) {
            // for earlier iOS version
            UITableView.appearance().separatorColor = .clear
        }
    }

    var body: some View {
        List {
            Group {
                header
                    .padding(.bottom, 18)
                content
            }
            .withCustomListStyle()
        }
        .refreshable {
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
    }

    private var content: some View {
        Group {
            Text(L10n.tokens)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(Asset.Colors.night.color))

            ForEach(viewModel.items, id: \.token.symbol) {
                tokenCell(isVisible: true, wallet: $0)
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
                        tokenCell(isVisible: false, wallet: $0)
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
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(Asset.Colors.night.color))
                }
            }
        )
            .buttonStyle(PlainButtonStyle())
    }

    private func tokenCell(isVisible: Bool, wallet: Wallet) -> some View {
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
//                tokenDetailIsPresented.toggle()
                viewModel.tokenClicked(wallet: wallet)
            }
    }
}

private extension View {
    @ViewBuilder func withCustomListStyle() -> some View {
        listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparatorHiddenForIOS15()
    }

    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func listRowSeparatorHiddenForIOS15() -> some View {
        if #available(iOS 15, *) {
            self.listRowSeparator(.hidden)
        } else {
            self
        }
    }
}
