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
    let token: Token?

    func makeUIView(context _: UIViewRepresentableContext<CoinLogoImageViewRepresentable>)
    -> CoinLogoImageView {
        CoinLogoImageView(size: size)
    }

    func updateUIView(_ imageView: CoinLogoImageView,
                      context _: UIViewRepresentableContext<CoinLogoImageViewRepresentable>)
    {
        imageView.setUp(token: token)
    }
}
