//
//  ListDividerRow.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation
import SwiftUI

struct ListDividerReceiveItem {
    var id: String = UUID().uuidString
}

extension ListDividerReceiveItem: ReceiveRendableItem {
    func render() -> some View {
        ListDividerReceiveView()
    }
}
