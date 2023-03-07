//
//  RefundBannerReceiveCellView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation
import SwiftUI
import KeyAppUI

struct RefundBannerReceiveView: View {
    var item: RefundBannerReceiveItem

    var body: some View {
        HStack {
            Text(item.text)
                .foregroundColor(Color(Asset.Colors.night.color))
                .fontWeight(.semibold)
                .apply(style: .text2)
                .multilineTextAlignment(.leading)
            Image(uiImage: .receiveBills)
        }
        .padding(.horizontal, 20)
        .background(Color(UIColor.cdf6cd))
        .cornerRadius(radius: 16, corners: .allCorners)
    }
}

struct RefundBannerReceiveCellView_Previews: PreviewProvider {
    static var previews: some View {
        RefundBannerReceiveView(item: .init(text: "Some banner text"))
    }
}
