//
//  ListDividerReceiveCellView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07.03.2023.
//

import KeyAppUI
import SwiftUI

struct ListDividerReceiveView: View {
    var body: some View {
        Divider()
            .frame(height: 1)
            .overlay(Color(Asset.Colors.rain.color))
            .padding(.leading, 20)
    }
}

struct ListDividerReceiveCellView_Previews: PreviewProvider {
    static var previews: some View {
        ListDividerReceiveView()
    }
}
