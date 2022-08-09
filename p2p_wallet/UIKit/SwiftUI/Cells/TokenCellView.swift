//
//  TokenCellView.swift
//  p2p_wallet
//
//  Created by Ivan on 05.08.2022.
//

import KeyAppUI
import SwiftUI

struct TokenCellView: View {
    let model: Model

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            TokenImageView(imageURL: model.imageUrl, wrappedImage: model.wrappedImage)
            VStack(alignment: .leading, spacing: 4) {
                Text(model.title)
                    .font(uiFont: .font(of: .text2))
                    .foregroundColor(Color(Asset.Colors.night.color))
                Text(model.subtitle)
                    .font(uiFont: .font(of: .label1))
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            Spacer()
            Text(model.amount)
                .font(uiFont: .font(of: .text3, weight: .bold))
                .foregroundColor(Color(Asset.Colors.night.color))
        }
    }
}

// MARK: - Model

extension TokenCellView {
    struct Model {
        let imageUrl: String
        let title: String
        let subtitle: String
        let amount: String
        var wrappedImage: UIImage?
    }
}
