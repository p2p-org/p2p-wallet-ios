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
                banner
                scrollingContent
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .background(Color(Asset.Colors.smoke.color))
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
                    Color(.fern)
                        .frame(height: 200)
                        .cornerRadius(16)
                }
                Image(uiImage: .homeBannerPerson)
            }
            VStack(spacing: 19) {
                VStack(spacing: 8) {
                    Text(L10n.topUpYourAccountToGetStarted)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .text1, weight: .semibold))
                    Text(L10n.makeYourFirstDepositOrBuyCryptoWithYourCreditCardOrApplePay)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .text3))
                        .padding(.horizontal, 24)
                }
                Button(
                    action: {
                        viewModel.receiveClicked()
                    },
                    label: {
                        Text(L10n.receive)
                            .foregroundColor(Color(Asset.Colors.night.color))
                            .font(uiFont: .font(of: .text4, weight: .semibold))
                            .frame(height: 48)
                            .frame(maxWidth: .infinity)
                            .background(Color(Asset.Colors.snow.color))
                            .cornerRadius(8)
                            .padding(.horizontal, 24)
                    }
                )
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
    }

    private var scrollingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.coinsToBuy)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .title3, weight: .semibold))
                .padding(.horizontal, 16)
            VStack(spacing: 12) {
                ForEach(Array(viewModel.popularCoins.indices), id: \.self) { index in
                    let coin = viewModel.popularCoins[index]
                    Button(
                        action: {
                            viewModel.coinTapped(at: index)
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
