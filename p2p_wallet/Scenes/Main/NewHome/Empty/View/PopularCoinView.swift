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
    let action: () -> Void

    init(
        title: String,
        subtitle: String,
        actionTitle: String,
        image: UIImage,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.image = image
        self.action = action
    }

    var body: some View {
        ZStack {
            Color(UIColor.f8f8fa)
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
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                }
                .padding(.leading, 16)
                Spacer()
                Button(
                    action: action,
                    label: {
                        Text(actionTitle)
                            .foregroundColor(.black)
                            .font(.system(size: 13, weight: .medium))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                    }
                )
                    .background(Color(Asset.Colors.rain.color))
                    .cornerRadius(8)
                    .frame(height: 32)
                    .padding(.trailing, 16)
            }
        }
    }
}
