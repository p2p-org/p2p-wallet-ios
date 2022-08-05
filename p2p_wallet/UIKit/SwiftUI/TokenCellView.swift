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
            TokenImageView(imageUrl: model.imageUrl, wrappedImage: model.wrappedImage)
            VStack(spacing: 4) {
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

//    func setUp(token: Token? = nil, placeholder: UIImage? = nil) {
//        // default
//        wrappingView.alpha = 0
//        backgroundColor = .clear
//        tokenIcon.isHidden = false
//        seed = nil
//
//        // with token
//        if let token = token {
//            if let image = token.image {
//                tokenIcon.image = image
//            } else {
//                let key = token.symbol.isEmpty ? token.address : token.symbol
//                var seed = Self.cachedJazziconSeeds[key]
//                if seed == nil {
//                    seed = UInt32.random(in: 0 ..< 10_000_000)
//                    Self.cachedJazziconSeeds[key] = seed
//                }
//
//                tokenIcon.isHidden = true
//                self.seed = seed
//
//                tokenIcon.setImage(urlString: token.logoURI) { [weak self] result in
//                    switch result {
//                    case .success:
//                        self?.tokenIcon.isHidden = false
//                        self?.seed = nil
//                    case .failure:
//                        self?.tokenIcon.isHidden = true
//                    }
//                }
//            }
//        } else {
//            tokenIcon.image = placeholder
//        }
//
//        // wrapped by
//        if let wrappedBy = token?.wrappedBy {
//            wrappingView.alpha = 1
//            wrappingTokenIcon.image = wrappedBy.image
//        }
//    }
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
