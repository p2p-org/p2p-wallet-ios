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
        List {
            Group {
                banner
                    .topPadding()
                    .padding(.bottom, 32)
                scrollingContent
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

    private var banner: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    Color(.clear)
                        .frame(height: 87)
                    Color(.cdf6cd)
                        .frame(height: 200)
                        .cornerRadius(16)
                }
                Image(uiImage: .homeBannerPerson)
            }
            VStack(spacing: 19) {
                VStack(spacing: 12) {
                    Text(L10n.topUpYourAccountToGetStarted)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .fontWeight(.bold)
                        .apply(style: .text1)
                    Text(L10n.makeYourFirstDepositOrBuyCryptoWithYourCreditCardOrApplePay)
                        .apply(style: .text3)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .padding(.horizontal, 24)
                }
                Text(L10n.receive)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .text4, weight: .semibold))
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color(Asset.Colors.snow.color))
                    .cornerRadius(8)
                    .padding(.top, 3)
                    .padding(.horizontal, 24)
                    .onTapGesture {
                        viewModel.topUp.send()
                    }
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
    }

    private var scrollingContent: some View {
        Group {
            Text(L10n.popularCoins)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .title3, weight: .semibold))
                .padding(.bottom, 16)
            ForEach(Array(viewModel.popularCoins.indices), id: \.self) { index in
                let coin = viewModel.popularCoins[index]
                PopularCoinView(
                    title: coin.title,
                    subtitle: coin.amount,
                    actionTitle: coin.actionTitle,
                    image: coin.image
                ).onTapGesture {
                    coinTapped(at: index)
                }
                .padding(.bottom, 16)
            }
        }
    }

    private func coinTapped(at index: Int) {
        viewModel.buyTapped(index: index)
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
            padding(.top, 12)
        } else {
            padding(.top, 0)
        }
    }
}
