//
//  SpacerReceiveCellItem.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation
import SwiftUI

struct SpacerReceiveItem {
    var id: String = UUID().uuidString
}

extension SpacerReceiveItem: ReceiveRendableItem {
    func render() -> some View {
        Color(UIColor.clear)
            .frame(height: 8)
    }
}
