//
//  TokenIconView.swift
//  p2p_wallet
//
//  Created by Ivan on 08.08.2022.
//

import Kingfisher
import SwiftUI

struct TokenImageView: View {
    let imageURL: String
    let image: UIImage? = nil
    let wrappedImage: UIImage?
    let wrappedImageURL: String? = nil

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            self.coinLogoView(image: image, imageURL: imageURL)?
                .frame(width: 50, height: 50)
                .cornerRadius(16)
            self.coinLogoView(image: wrappedImage, imageURL: wrappedImageURL)?
                .frame(width: 16, height: 16)
        }
    }

    func coinLogoView(image: UIImage?, imageURL imageURLString: String?) -> CoinLogoView? {
        if let image = image {
            return CoinLogoView(image: image, imageURL: nil)
        } else if let imageURLString = imageURLString, let imageURL = URL(string: imageURLString) {
            return CoinLogoView(image: nil, imageURL: imageURL)
        }
        return nil
    }
}
