//
//  TokenIconView.swift
//  p2p_wallet
//
//  Created by Ivan on 08.08.2022.
//

import Kingfisher
import SwiftUI

struct TokenImageView: View {
    let imageUrl: String
    let wrappedImage: UIImage?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.black
                .frame(width: 48, height: 48)
                .cornerRadius(16)
            if let wrappedImage = wrappedImage {
                Image(uiImage: wrappedImage)
                    .frame(width: 16, height: 16)
                    .cornerRadius(5)
            }
        }
    }
}
