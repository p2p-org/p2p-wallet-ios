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
            ) {
                viewModel.showDeposits()
            }
            .padding(.bottom, 8)
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
            ScrollView {
                VStack {
                    if viewModel.loading && viewModel.invests.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if let market = viewModel.invests {
                        // Cells
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
            }
            .frame(maxHeight: .infinity)
        }.onReceive(updating) { _ in Task { try await viewModel.update() } }
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
