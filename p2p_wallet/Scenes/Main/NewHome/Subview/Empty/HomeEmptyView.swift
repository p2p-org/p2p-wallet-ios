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
            .padding(.top, 22)
            .padding(.bottom, 16)
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
                    Color(Asset.Colors.smoke.color)
                        .frame(height: 87)
                    Color(.fern)
                        .frame(height: 200)
                        .cornerRadius(16)
                }
                Image(uiImage: .homeBannerPerson)
            }
            VStack(spacing: 19) {
                VStack(spacing: 13) {
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
            Text(L10n.currenciesAvailable)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .title3, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.top, 3)
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
