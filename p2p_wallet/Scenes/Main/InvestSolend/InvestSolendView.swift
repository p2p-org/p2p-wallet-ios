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

    var body: some View {
        NavigationView {
            VStack {
                // Banner
                InvestSolendBannerView(viewModel: InvestSolendBannerViewModel())
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

                // Market
                ScrollView {
                    VStack {
                        if viewModel.loading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else if let market = viewModel.market {
                            // Cells
                            ForEach(market, id: \.asset.symbol) { asset, market, userDeposit in
                                Button {
                                    viewModel.assetClicked(asset, market: market)
                                } label: {
                                    InvestSolendCell(
                                        asset: asset,
                                        deposit: userDeposit?.depositedAmount,
                                        apy: market?.supplyInterest
                                    )
                                }
                            }
                        }
                        Spacer(minLength: 20)
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .navigationBarTitle(L10n.earnAYield)
        }
    }
}
