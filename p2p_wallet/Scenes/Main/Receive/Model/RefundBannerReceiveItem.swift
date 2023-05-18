//
//  RefundBannerReceiveCellItem.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation
import SwiftUI


struct RefundBannerReceiveItem {
    var id: String = UUID().uuidString
    let text: String
}

extension RefundBannerReceiveItem: ReceiveRendableItem {
    func render() -> some View {
        RefundBannerReceiveView(item: self)
    }
}
