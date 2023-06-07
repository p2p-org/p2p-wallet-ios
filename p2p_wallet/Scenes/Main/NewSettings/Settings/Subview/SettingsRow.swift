//
//  SettingsRow.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07/06/2023.
//

import Foundation
import SwiftUI
import KeyAppUI

struct SettingsRow<Leading: View>: View {
    
    let title: String
    let withArrow: Bool
    @ViewBuilder let leading: Leading
    
    var body: some View {
        HStack(spacing: 12) {
            leading
                .frame(width: 24, height: 24)
            Text(title)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .text2))
                .lineLimit(1)
            if withArrow {
                Spacer()
                Image(uiImage: .cellArrow)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
        }
    }
}

struct SettingsRow_Preview: PreviewProvider {
    static var previews: some View {
        SettingsRow(title: "Example", withArrow: true) {
            Image(uiImage: UIImage.recoveryKit)
                .overlay(
                    AlertIndicator(fillColor: Color(Asset.Colors.rose.color)).offset(x: 2.5, y: -2.5),
                    alignment: .topTrailing
                )
        }
    }
}
