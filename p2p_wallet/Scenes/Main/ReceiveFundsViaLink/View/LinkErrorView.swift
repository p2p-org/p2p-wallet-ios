//
//  LinkErrorView.swift
//  p2p_wallet
//
//  Created by Ivan on 28.03.2023.
//

import SwiftUI
import KeyAppUI

struct LinkErrorView: View {
    
    let model: Model
    let okayClicked: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                Image(uiImage: model.image)
                Text(model.title)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .title1, weight: .semibold))
                Text(model.subtitle)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .text4))
            }
            Spacer()
            Button(
                action: {
                    okayClicked()
                },
                label: {
                    Text(L10n.okay)
                        .foregroundColor(Color(Asset.Colors.snow.color))
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.night.color))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                }
            )
        }
        .padding(.bottom, 32)
    }
}

// MARK: - Model

extension LinkErrorView {
    struct Model {
        let title: String
        let subtitle: String
        let image: UIImage
    }
}
