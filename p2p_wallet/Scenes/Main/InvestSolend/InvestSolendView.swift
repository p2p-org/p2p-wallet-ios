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
                                NavigationLink(destination: DepositSolendView(viewModel: try!
                                        .init(initialAsset: asset))) {
                                    InvestSolendCell(
                                        asset: asset,
                                        deposit: userDeposit?.depositedAmount,
                                        apy: market?.supplyInterest
                                    )
                                }
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text(L10n.somethingWentWrong + "...")
                                Button {
                                    Task { try await viewModel.update() }
                                } label: {
                                    Text(L10n.tryAgain)
                                }
                                Spacer()
                            }
                        }
                        Spacer(minLength: 20)
                    }
                }
                .frame(maxHeight: .infinity)
                .navigationBarHidden(true)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        InvestSolendView(viewModel: .init(mocked: true))
    }
}
