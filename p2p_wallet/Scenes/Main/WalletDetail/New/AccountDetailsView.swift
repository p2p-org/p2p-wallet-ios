//
//  AccountDetailsView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.02.2023.
//

import KeyAppUI
import SwiftUI

struct AccountDetailsView: View {
    @ObservedObject var detailAccount: AccountDetailsViewModel
    @ObservedObject var historyList: HistoryViewModel

    var body: some View {
        NewHistoryView(viewModel: historyList, header: header)
            .background(Color(Asset.Colors.smoke.color).ignoresSafeArea())
    }

    var header: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text(detailAccount.rendableAccountDetails.amountInToken)
                    .fontWeight(.bold)
                    .apply(style: .largeTitle)
                    .foregroundColor(Color(Asset.Colors.night.color))
                Text(detailAccount.rendableAccountDetails.amountInFiat)
                    .apply(style: .text3)
                    .foregroundColor(Color(Asset.Colors.night.color))
            }
            .padding(.top, 24)

            HStack(spacing: 32) {
                ForEach(detailAccount.rendableAccountDetails.actions) { action in
                    CircleButton(title: action.title, image: action.icon) {
                        detailAccount.rendableAccountDetails.onAction(action)
                    }
                }
            }
            .padding(.top, 32)
        }
    }
}

struct AccountDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let historyList = HistoryViewModel(
            mock: [MockedRendableListTransactionItem.send()]
        )
        historyList.fetch()

        return AccountDetailsView(
            detailAccount: .init(
                rendableAccountDetails: MockRendableAccountDetails(
                    title: "USDC",
                    amountInToken: "1 000.97 USDC",
                    amountInFiat: "1 000.97 USDC",
                    actions: [.buy, .receive(.none), .send, .swap(nil)],
                    onAction: { _ in }
                )
            ),
            historyList: historyList
        )
    }
}
