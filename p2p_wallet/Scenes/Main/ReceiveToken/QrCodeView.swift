//
//  QrCodeView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import Foundation

class QrCodeView: BEView {
    private let size: CGFloat
//    private let coinLogoSize: CGFloat
    
    private lazy var qrCodeView = UIImageView(backgroundColor: .white)
//    private lazy var logoImageView: CoinLogoImageView = {
//        let imageView = CoinLogoImageView(size: 50)
//        imageView.layer.borderWidth = 2
//        imageView.layer.borderColor = UIColor.textWhite.cgColor
//        return imageView
//    }()
    
    init(size: CGFloat, coinLogoSize: CGFloat) {
        self.size = size
//        self.coinLogoSize = coinLogoSize
        super.init(frame: .zero)
    }
    
    override func commonInit() {
        super.commonInit()
        configureForAutoLayout()
        autoSetDimensions(to: .init(width: size, height: size))
//        logoImageView.autoSetDimensions(to: .init(width: coinLogoSize, height: coinLogoSize))
        
        addSubview(qrCodeView)
        qrCodeView.autoPinEdgesToSuperviewEdges()
        
//        addSubview(logoImageView)
//        logoImageView.autoCenterInSuperview()
    }
    
    func setUp(wallet: Wallet?) {
        if let pubkey = wallet?.pubkey {
            qrCodeView.setQrCode(string: pubkey)
//            logoImageView.setUp(wallet: wallet)
//            logoImageView.isHidden = false
        } else {
            qrCodeView.setQrCode(string: "<placeholder>")
//            logoImageView.isHidden = true
        }
    }
    
    func setUp(string: String?) {
        qrCodeView.setQrCode(string: string)
//        logoImageView.isHidden = true
    }
    
    @discardableResult
    func with(string: String?) -> Self {
        setUp(string: string)
        return self
    }
}
