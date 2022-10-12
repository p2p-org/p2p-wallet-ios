// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
import Resolver
import SolanaSwift
import Solend
import SwiftUI

struct InvestSolendView: View {
    @StateObject var viewModel: InvestSolendViewModel

    let updating = Timer.publish(every: 60 * 10, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack {
                // Title
                HStack {
                    Text(L10n.earnAYield)
                        .fontWeight(.bold)
                        .apply(style: .largeTitle)
                    Spacer()
                }
                .padding(.top, 20)
                .padding(.horizontal, 16)

                // Banner
                InvestSolendBannerView(
                    viewModel: InvestSolendBannerViewModel(
                        dataService: viewModel.dataService,
                        actionService: viewModel.actionService
                    )
                ) { action in
                    switch action {
                    case .showDeposit:
                        viewModel.showDeposits()
                    case .retry:
                        viewModel.retry()
                    }
                }
                .padding(.bottom, 16)
                .padding(.horizontal, 16)

                // Title
                HStack {
                    Text(L10n.depositToEarnAYield)
                        .fontWeight(.semibold)
                        .apply(style: .text1)
                    Spacer()
                    Text(L10n.apy)
                        .fontWeight(.semibold)
                        .apply(style: .text1)
                }.padding(.horizontal, 16)

                // Invests
                VStack {
                    if viewModel.loading && viewModel.invests.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if let market = viewModel.invests {
                        if !viewModel.apyLoaded {
                            ratesError
                        }
                        ForEach(market, id: \.asset.symbol) { asset, market, userDeposit in
                            Button {
                                viewModel.assetClicked(asset, market: market)
                            } label: {
                                InvestSolendCell(
                                    asset: asset,
                                    deposit: userDeposit?.depositedAmount,
                                    apy: market?.supplyInterest,
                                    isLoading: viewModel.loading
                                )
                            }
                        }
                    }
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
            }
        }.onReceive(updating) { _ in Task { try await viewModel.update() } }
    }

    private var ratesError: some View {
        HStack(spacing: 8) {
            Image(uiImage: .solendSubtract)
            Text(L10n.ThereSAProblemShowingTheRates.tryAgainLater)
                .font(uiFont: .font(of: .text3))
                .foregroundColor(Color(Asset.Colors.rose.color))
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 64)
        .frame(maxWidth: .infinity)
        .background(Color(Asset.Colors.rose.color.withAlphaComponent(0.1)))
        .cornerRadius(8)
    }
}

struct InvestSolendView_Previews: PreviewProvider {
    static var previews: some View {
        InvestSolendView(
            viewModel: .init(
                dataService: SolendDataServiceMock(),
                actionService: SolendActionServiceMock()
            )
        )
    }
}
