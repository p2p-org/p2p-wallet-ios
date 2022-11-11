//
//  RecoveryKitSection.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 02.09.2022.
//

import KeyAppUI
import SwiftUI

struct RecoveryKitRow: View {
    let icon: UIImage
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(uiImage: icon)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .fontWeight(.semibold)
                        .apply(style: .text2)
                        .foregroundColor(Color(Asset.Colors.night.color))
                    Text(subtitle)
                        .apply(style: .label1)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                }.padding(.leading, 12)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 72)

            // Divider
            Rectangle()
                .fill(Color(Asset.Colors.rain.color))
                .frame(height: 1)
                .edgesIgnoringSafeArea(.horizontal)
                .padding(.leading, 20)
        }
    }
}

struct RecoveryKitRow_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryKitRow(icon: .appleIcon, title: "Apple", subtitle: "dragon@apple.com")
    }
}
