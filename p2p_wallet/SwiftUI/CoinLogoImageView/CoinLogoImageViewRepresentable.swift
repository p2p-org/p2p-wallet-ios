//
//  CoinLogoImageViewRepresentable.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/08/2022.
//

import Foundation
import SolanaSwift
import SwiftUI
import UIKit

struct CoinLogoImageViewRepresentable: UIViewRepresentable {
    let size: CGFloat
    let args: Args

    func makeUIView(context _: UIViewRepresentableContext<CoinLogoImageViewRepresentable>) -> CoinLogoImageView {
        CoinLogoImageView(size: size)
    }

    func updateUIView(_ imageView: CoinLogoImageView,
                      context _: UIViewRepresentableContext<CoinLogoImageViewRepresentable>)
    {
        switch args {
        case let .token(token):
            imageView.setUp(token: token)
        case let .manual(preferredImage, url, key, wrapped):
            imageView.setup(preferredImage: preferredImage, url: url, key: key, wrapped: wrapped)
        }
    }
    
    enum Args {
        case token(Token?)
        case manual(preferredImage: UIImage?, url: URL?, key: String, wrapped: Bool)
    }
}

