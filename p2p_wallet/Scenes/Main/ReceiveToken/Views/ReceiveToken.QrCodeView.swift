//
//  QrCodeView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/03/2021.
//

import Foundation
import SolanaSwift

extension ReceiveToken {
    class QrCodeView: BEView {
        private let size: CGFloat
        private let coinLogoSize: CGFloat
        private let showCoinLogo: Bool

        private lazy var qrCodeImageView = QrCodeImageView(backgroundColor: .clear)
        private lazy var logoImageView: CoinLogoImageView = {
            let imageView = CoinLogoImageView(size: coinLogoSize)
            imageView.layer.borderWidth = 4
            imageView.layer.borderColor = UIColor.textWhite.cgColor
            imageView.layer.cornerRadius = coinLogoSize / 2
            imageView.layer.masksToBounds = true
            return imageView
        }()

        init(size: CGFloat, coinLogoSize: CGFloat, showCoinLogo: Bool = true) {
            self.size = size
            self.coinLogoSize = coinLogoSize
            self.showCoinLogo = showCoinLogo
            super.init(frame: .zero)
        }

        override func commonInit() {
            super.commonInit()
            configureForAutoLayout()
            autoSetDimensions(to: .init(width: size, height: size))
            logoImageView.autoSetDimensions(to: .init(width: coinLogoSize, height: coinLogoSize))

            addSubview(qrCodeImageView)
            qrCodeImageView.autoPinEdgesToSuperviewEdges()

            if showCoinLogo {
                addSubview(logoImageView)
                logoImageView.autoCenterInSuperview()
            }
        }

        func setUp(string: String?, token: Token? = nil) {
            qrCodeImageView.setQrCode(string: string)
            logoImageView.setUp(token: token ?? .nativeSolana)
        }

        @discardableResult
        func with(string: String?, token: Token? = nil) -> Self {
            setUp(string: string, token: token)
            return self
        }
    }

    private class QrCodeImageView: UIImageView {
        fileprivate func setQrCode(string: String?) {
            guard let string = string else {
                image = nil
                return
            }

            if let imageFromCache = UIImageView.qrCodeCache.object(forKey: string as NSString) {
                image = imageFromCache
                return
            }

            let data = string.data(using: String.Encoding.ascii)

            DispatchQueue.global().async {
                var image: UIImage?
                if let filter = CIFilter(name: "CIQRCodeGenerator") {
                    filter.setValue(data, forKey: "inputMessage")
                    let transform = CGAffineTransform(scaleX: 10, y: 10)

                    if let output = filter.outputImage?.transformed(by: transform) {
                        let qrCode = UIImage(ciImage: output)
                        image = qrCode
                        UIImageView.qrCodeCache.setObject(qrCode, forKey: string as NSString)
                    }
                }
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
}
