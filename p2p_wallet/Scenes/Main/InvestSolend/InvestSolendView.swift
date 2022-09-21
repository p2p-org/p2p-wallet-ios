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
            
            // Card
            VStack(alignment: .leading) {
                // Title
                Text(L10n.totalRewardsEarned)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .apply(style: .text3)
                
                // Reward
                Text("$ 0.0000000000")
                    .fontWeight(.bold)
                    .apply(style: .title1)
                    .padding(.top, 8)
                
                // Show deposit
                HStack {
                    Text(L10n.showDeposit("$ \(viewModel.totalDeposit.fixedDecimal(2))"))
                    Spacer()
                    Image(uiImage: Asset.MaterialIcon.accountBalanceWalletOutlined.image)
                }
                .padding(.all, 16)
                .background(
                    Color(Asset.Colors.snow.color)
                        .cornerRadius(radius: 12, corners: .allCorners)
                )
                .padding(.top, 16)
            }
            .padding(.all, 20)
            .frame(maxWidth: .infinity)
            .background(
                Color(Asset.Colors.rain.color)
                    .cornerRadius(radius: 28, corners: .allCorners)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
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
            FixedList {
                if viewModel.loading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
                // Cells
                ForEach(viewModel.market, id: \.asset.symbol) { asset, market, userDeposit in
                    NavigationLink(destination: DepositSolendView(viewModel: try! .init(initialAsset: asset))) {
                        InvestSolendCell(
                            asset: asset,
                            deposit: userDeposit?.depositedAmount,
                            apy: market?.supplyInterest
                        )
                    }
                        .padding(.trailing, 20)
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        InvestSolendView(viewModel: try! .init(mocked: true))
    }
}
