//
//  SwipeActionButton.swift
//  p2p_wallet
//
//  Created by Ivan on 09.08.2022.
//

import KeyAppUI
import SwiftUI

struct SwipeActionButton: View, Identifiable {
    static let width: CGFloat = 70

    let id = UUID()
    let icon: Image?
    let tint: Color?
    let action: () -> Void

    init(
        icon: Image? = nil,
        tint: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.action = action
        self.tint = tint ?? .gray
    }

    var body: some View {
        ZStack {
            tint
            icon
                .frame(width: SwipeActionButton.width)
        }
    }
}
