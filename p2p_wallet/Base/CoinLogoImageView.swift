//
//  CoinLogoImageView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/01/2021.
//

import Foundation

class CoinLogoImageView: BEView {
    lazy var imageView = UIImageView(tintColor: .textBlack)
    private var placeholder: UIView?
    
    override func commonInit() {
        super.commonInit()
        addSubview(imageView)
        imageView.autoCenterInSuperview()
        imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.66).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
    }
    
    func setUp(wallet: Wallet? = nil) {
        placeholder?.isHidden = true
        imageView.isHidden = false
        backgroundColor = .clear
        if let wallet = wallet {
            imageView.image = wallet.image
            backgroundColor = wallet.backgroundColor
        } else if let placeholder = placeholder {
            placeholder.isHidden = false
            imageView.isHidden = true
        } else {
            backgroundColor = .gray
        }
    }
    
    func with(wallet: Wallet) -> Self {
        setUp(wallet: wallet)
        return self
    }
    
    func with(placeholder: UIView) -> Self {
        self.placeholder?.removeFromSuperview()
        self.placeholder = placeholder
        insertSubview(placeholder, at: 0)
        placeholder.autoPinEdgesToSuperviewEdges()
        setUp()
        return self
    }
}
