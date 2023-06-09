//
//  HomeEmptyView.swift
//  p2p_wallet
//
//  Created by Ivan on 01.08.2022.
//

import Combine
import KeyAppUI
import SwiftUI

struct HomeEmptyView: View {
    @ObservedObject var viewModel: HomeEmptyViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 36) {
                HomeBannerView(
                    backgroundColor: Asset.Colors.lightSea.color,
                    image: .homeBannerPerson,
                    title: L10n.topUpYourAccountToGetStarted,
                    subtitle: L10n.makeYourFirstDepositOrBuyCryptoWithYourCreditCardOrApplePay,
                    actionTitle: L10n.addMoney,
                    action: { [weak viewModel] in viewModel?.receiveClicked() }
                )
                scrollingContent
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .background(Color(Asset.Colors.smoke.color))
        .customRefreshable {
            await viewModel.reloadData()
        }
    }

    private var scrollingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.currenciesAvailable)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .title3, weight: .semibold))
                .padding(.horizontal, 16)
            VStack(spacing: 12) {
                ForEach(Array(viewModel.popularCoins.indices), id: \.self) { index in
                    let coin = viewModel.popularCoins[index]
                    Button(
                        action: {
                            viewModel.buyTapped(index: index)
                        },
                        label: {
                            PopularCoinView(
                                title: coin.title,
                                subtitle: coin.amount,
                                actionTitle: coin.actionTitle,
                                image: coin.image
                            )
                        }
                    )
                }
            }
        }
    }
}
