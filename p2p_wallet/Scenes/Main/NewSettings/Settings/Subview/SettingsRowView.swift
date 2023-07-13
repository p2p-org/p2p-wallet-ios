//
//  SettingsRow.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07/06/2023.
//

import Foundation
import SwiftUI
import KeyAppUI

struct SettingsRowView<Leading: View>: View {
    
    let title: String
    let withArrow: Bool
    @ViewBuilder let leading: Leading
    
    var body: some View {
        HStack(spacing: 12) {
            leading
                .frame(width: 24, height: 24)
            Text(title)
                .foregroundColor(Color(.night))
                .font(uiFont: .font(of: .text2))
                .lineLimit(1)
            if withArrow {
                Spacer()
                Image(.cellArrow)
                    .foregroundColor(Color(.mountain))
            }
        }
    }
}

struct SettingsRow_Preview: PreviewProvider {
    static var previews: some View {
        SettingsRowView(title: "Example", withArrow: true) {
            Image(.recoveryKit)
                .overlay(
                    AlertIndicatorView(fillColor: Color(.rose)).offset(x: 2.5, y: -2.5),
                    alignment: .topTrailing
                )
        }
    }
}
