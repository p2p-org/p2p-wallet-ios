//
//  HomeCashView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 26.06.2023.
//

import KeyAppUI
import SwiftUI

struct HomeCashView: View {
    @ObservedObject var viewModel: HomeCashViewModel

    var body: some View {
        VStack {
            // Header
            HomeHeaderCard(
                title: "ALL ACCOUNTS",
                balance: viewModel.totalAmountInFiat,
                balanceDetail: .urls(value: viewModel.iconsURL)
            ) {
                HStack(spacing: 12) {
                    NewTextButton(
                        title: "Add money",
                        size: .small,
                        style: .primaryWhite,
                        expandable: true,
                        trailing: Asset.MaterialIcon.add.image
                    ) {}
                    NewTextButton(
                        title: "Withdraw",
                        size: .small,
                        style: .second,
                        expandable: true,
                        trailing: Asset.MaterialIcon.arrowUpward.image
                    ) {}
                }
            }

            // Banner
            HomeSendWithZeroFeeBanner()
        }
    }
}

struct HomeCashView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.ignoresSafeArea()
            HomeCashView(viewModel: .init(totalAmountInFiat: "$50", iconsURL: []))
        }
    }
}
