//
//  ListRowReceiveCellView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation
import SwiftUI

struct ListReceiveItem {
    var id: String
    var title: String
    var description: String
    var showTopCorners: Bool
    var showBottomCorners: Bool
}

extension ListReceiveItem: ReceiveRendableItem {
    func render() -> some View {
        ListReceiveItemView(item: self)
    }
}
