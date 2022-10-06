//
//  SolendBanner.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.10.2022.
//

import SwiftUI
import KeyAppUI

struct SolendBanner: ViewModifier {
    let backgroundColor: Color
    
    func body(content: Content) -> some View {
        ZStack {
            backgroundColor
            content
                .foregroundColor(Color(Asset.Colors.night.color))
                .padding(.top, 36)
                .padding(.bottom, 20)
                .padding(.horizontal, 20)
        }
        .cornerRadius(28)
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }
}
