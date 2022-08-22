//
//  PopularCoinView.swift
//  p2p_wallet
//
//  Created by Ivan on 02.08.2022.
//

import KeyAppUI
import SwiftUI

struct PopularCoinView: View {
    let title: String
    let subtitle: String
    let actionTitle: String
    let image: UIImage

    init(
        title: String,
        subtitle: String,
        actionTitle: String,
        image: UIImage
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.image = image
    }

    var body: some View {
        ZStack {
            Color(Asset.Colors.smoke.color)
                .frame(height: 74)
                .cornerRadius(20)
            HStack {
                HStack(spacing: 12) {
                    Image(uiImage: image)
                        .frame(width: 42, height: 42)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(title)
                        Text(subtitle)
                    }
                    .font(uiFont: .font(of: .text1, weight: .bold))
                    .foregroundColor(Color(Asset.Colors.night.color))
                }
                .padding(.leading, 16)
                Spacer()
                Text(actionTitle)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .text4, weight: .bold))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(Asset.Colors.rain.color))
                    .cornerRadius(8)
                    .frame(height: 32)
                    .padding(.trailing, 16)
            }
        }
    }
}
