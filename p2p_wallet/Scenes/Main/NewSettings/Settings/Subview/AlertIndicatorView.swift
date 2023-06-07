//
//  AlertIndicatorView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07/06/2023.
//

import Foundation
import SwiftUI
import KeyAppUI

struct AlertIndicator: View {
    let fillColor: Color
    
    var body: some View {
        ZStack {
            Circle()
            .fill(fillColor)
            Circle()
                .strokeBorder(Color(Asset.Colors.snow.color), lineWidth: 1.5)
        }
        .frame(width: 9.5, height: 9.5)
    }
}
