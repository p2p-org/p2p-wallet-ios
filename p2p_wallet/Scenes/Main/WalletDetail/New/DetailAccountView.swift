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
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct DetailAccountView_Previews: PreviewProvider {
    static var previews: some View {
        DetailAccountView()
    }
}
