//
//  CoinLogoImageView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/01/2021.
//

import Foundation

class CoinLogoImageView: BEView {
    lazy var imageView = UIImageView(tintColor: .textBlack)
    
    override func commonInit() {
        super.commonInit()
        addSubview(imageView)
        imageView.autoCenterInSuperview()
        imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.66).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        backgroundColor = .gray
    }
    
    func setUp(wallet: Wallet) {
        imageView.image = wallet.image
        backgroundColor = wallet.backgroundColor
    }
    
    func with(wallet: Wallet) -> Self {
        setUp(wallet: wallet)
        return self
    }
}
