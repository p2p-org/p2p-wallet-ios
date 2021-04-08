//
//  CoinLogoImageView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/01/2021.
//

import Foundation

class CoinLogoImageView: BEView {
    lazy var imageView = UIImageView(tintColor: .textBlack)
    lazy var wrappedByFTXIcon = UIImageView(width: 12, height: 12, image: .wrappedByFTX)
    private var placeholder: UIView?
    
    override func commonInit() {
        super.commonInit()
        backgroundColor = .gray
        addSubview(imageView)
        imageView.autoPinEdgesToSuperviewEdges()
        let wrappedByView: UIImageView = {
            let imageView = UIImageView(width: 16, height: 16, image: .wrappedByBackground)
            imageView.addSubview(wrappedByFTXIcon)
            wrappedByFTXIcon.autoCenterInSuperview()
            return imageView
        }()
        addSubview(wrappedByView)
        wrappedByView.autoPinEdge(toSuperviewEdge: .trailing)
        wrappedByView.autoPinEdge(toSuperviewEdge: .bottom)
        wrappedByView.alpha = 0 // UNKNOWN: isHidden not working
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        wrappedByFTXIcon.superview?.addShadow(ofColor: UIColor.textWhite.withAlphaComponent(0.25), radius: 2, offset: CGSize(width: 0, height: 2), opacity: 1)
    }
    
    func setUp(wallet: Wallet? = nil) {
        placeholder?.isHidden = true
        imageView.isHidden = false
        wrappedByFTXIcon.superview?.alpha = 0
        backgroundColor = .clear
        if let wallet = wallet {
            imageView.image = wallet.image
        } else if let placeholder = placeholder {
            placeholder.isHidden = false
            imageView.isHidden = true
        }
        if wallet?.wrappedBy != nil {
            wrappedByFTXIcon.superview?.alpha = 1
        }
    }
    
    func setUp(token: SolanaSDK.Token? = nil) {
        setUp(wallet: token != nil ? Wallet(programAccount: token!): nil)
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
        setUp(wallet: nil)
        return self
    }
}
