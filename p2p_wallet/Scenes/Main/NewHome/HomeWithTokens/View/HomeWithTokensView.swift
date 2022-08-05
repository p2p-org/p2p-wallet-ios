//
//  HomeWithTokensView.swift
//  p2p_wallet
//
//  Created by Ivan on 05.08.2022.
//

import AnalyticsManager
import KeyAppUI
import Resolver
import SwiftUI

struct HomeWithTokensView: View {
    @Injected private var analyticsManager: AnalyticsManager

    @ObservedObject var viewModel: HomeWithTokensViewModel

    init(viewModel: HomeWithTokensViewModel) {
        self.viewModel = viewModel
        analyticsManager.log(event: .mainScreenWalletsOpen)
    }

    var body: some View {
        RefreshableScrollView(
            refreshing: $viewModel.pullToRefreshPending,
            action: { viewModel.reloadData() },
            content: { scrollingContent }
        )
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
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
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
            ForEach(viewModel.items, id: \.title) { item in
                TokenCellView(model: item)
                    .frame(height: 72)
            }
        }
    }
}
