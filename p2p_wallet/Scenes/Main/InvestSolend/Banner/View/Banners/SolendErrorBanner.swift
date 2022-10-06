//
//  SolendErrorBanner.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 06.10.2022.
//

import SwiftUI
import KeyAppUI

struct SolendErrorBanner: View {
    let title: String
    let subtitle: String
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(uiFont: .font(of: .title3, weight: .semibold))
            Text(subtitle)
                .font(uiFont: .font(of: .text4))
                .multilineTextAlignment(.center)
            Button(
                action: { onTap() },
                label: {
                    Text(L10n.tryAgain)
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                        .frame(height: 48)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.snow.color))
                        .cornerRadius(12)
                        .padding(.top, 8)
                }
            )
        }
        .foregroundColor(Color(Asset.Colors.night.color))
        .padding(.top, 24)
        .padding(.bottom, 20)
        .padding(.horizontal, 20)
    }
}

struct SolendErrorBanner_Previews: PreviewProvider {
    static var previews: some View {
        SolendErrorBanner(
            title: "Something goes wrong",
            subtitle: "Contact Key App Team"
        ) {}
    }
}
