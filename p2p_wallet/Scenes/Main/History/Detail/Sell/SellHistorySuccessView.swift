//
//  SellHistorySuccessView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 19.12.2022.
//

import SwiftUI

struct SellHistorySuccessView: View {
    var body: some View {
        VStack {
            HistoryDetailHeaderView(token: .usdc, title: "Title", subtitle: "Subtitle")
        }.sheetHeader(title: L10n.theFundsWereSentToYourBankAccount)
    }
}

struct SellHistorySuccessView_Previews: PreviewProvider {
    static var previews: some View {
        SellHistorySuccessView()
    }
}
