//
//  InstructionsReceiveCellItem.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation
import SwiftUI

struct InstructionsReceiveCellItem {
    var id: String = UUID().uuidString
    let instructions: [(String, String)]
    let tip: String
}

extension InstructionsReceiveCellItem: ReceiveRendableItem {
    func render() -> some View {
        InstructionsReceiveView(item: self)
    }
}
