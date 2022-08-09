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
        RefreshableScrollView(
            refreshing: $viewModel.pullToRefreshPending,
            action: { viewModel.reloadData() },
            content: { scrollingContent }
        )
    }

    var scrollingContent: some View {
        VStack(spacing: 32) {
            banner
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.popularCoins)
                    .foregroundColor(.black)
                    .font(.system(size: 20, weight: .medium))
                ForEach(Array(viewModel.popularCoins.indices), id: \.self) { index in
                    let coin = viewModel.popularCoins[index]
                    VStack(spacing: 16) {
                        PopularCoinView(
                            title: coin.title,
                            subtitle: coin.amount,
                            actionTitle: coin.actionTitle,
                            image: coin.image,
                            action: {
                                coinTapped(at: index)
                            }
                        ).onTapGesture {
                            coinTapped(at: index)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    var banner: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    Color(.clear)
                        .frame(height: 51)
                    Color(._644aff)
                        .frame(height: 223)
                        .cornerRadius(12)
                }
                Image(uiImage: .homeBannerPerson)
            }
            VStack(spacing: 19) {
                VStack(spacing: 9) {
                    Text(L10n.topUpYourAccountToGetStarted)
                        .foregroundColor(Color(Asset.Colors.snow.color))
                        .font(.system(size: 18, weight: .medium))
                    Text(L10n.makeYourFirstDepositOrBuyWithYourCreditCardOrApplePay)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .foregroundColor(Color(.bfbfbf))
                        .font(.system(size: 15))
                        .frame(width: 264)
                }
                Button(
                    action: {
                        viewModel.topUp.send()
                    },
                    label: {
                        Text(L10n.topUp)
                            .foregroundColor(.black)
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 204, height: 49)
                            .background(Color(.ddfa2b))
                            .cornerRadius(8)
                    }
                )
            }
            .padding(.bottom, 18)
        }
    }

    private func coinTapped(at index: Int) {
        if index == 2 {
            viewModel.receiveRenBtcClicked()
        } else {
            viewModel.topUpCoin.send(index == 0 ? .usdc : .sol)
        }
    }
}
