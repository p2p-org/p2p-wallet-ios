//
//  DetailAccountView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.02.2023.
//

import SwiftUI

struct DetailAccountView: View {
    @ObservedObject var detailAccount: DetailAccountViewModel
    @ObservedObject var historyList: NewHistoryViewModel

    var body: some View {
        VStack {
            VStack {
                Text(detailAccount.rendableAccountDetail.amountInToken)
                Text(detailAccount.rendableAccountDetail.amountInFiat)
            }
            .padding(.top, 24)
            
            HStack(spacing: 32) {
                ForEach(detailAccount.rendableAccountDetail.actions) { action in
                    CircleButton(title: action.title, image: action.icon) {
                        detailAccount.rendableAccountDetail.onAction(action)
                    }
                }
                
            }
            
            NewHistoryView(viewModel: historyList)
        }
    }
}

struct DetailAccountView_Previews: PreviewProvider {
    static var previews: some View {
        DetailAccountView(
            detailAccount: .init(
                rendableAccountDetail: MockRendableAccountDetail(
                    amountInToken: "1 000.97 USDC",
                    amountInFiat: "1 000.97 USDC",
                    actions: [.buy, .receive, .send, .swap],
                    onAction: { _ in }
                )
            ),
            historyList: .init(
                mock: [MockedRendableListTransactionItem.send()]
            )
        )
    }
}
