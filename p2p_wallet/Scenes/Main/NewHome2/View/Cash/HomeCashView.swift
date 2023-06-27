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
        VStack(spacing: 8) {
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
                    ) {
                        viewModel.actionSubject.send(.buy)
                    }
                    NewTextButton(
                        title: "Withdraw",
                        size: .small,
                        style: .second,
                        expandable: true,
                        trailing: Asset.MaterialIcon.arrowUpward.image
                    ) {
                        viewModel.actionSubject.send(.cashOut)
                    }
                }
            }

            StrigaDocumentVerificationBannerView()
                .padding(.top, 12)
            // Banner
            HomeSendWithZeroFeeBanner {
                viewModel.actionSubject.send(.send)
            }
            ReceiveFreeUSDCBannerView {
                viewModel.actionSubject.send(.receive)
            }
        }
        .padding(.horizontal, 16)
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
