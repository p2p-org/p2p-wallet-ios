//
// Created by Giang Long Tran on 08.01.22.
//

import Foundation
import BEPureLayout
import RxSwift

protocol QrCodeImageRender {
    func render(username: String?, address: String?, token: SolanaSDK.Token?) -> Single<UIImage>
}

extension ReceiveToken {
    class QrCodeImageRenderImpl: QrCodeImageRender {
        private struct Theme {
            let backgroundColor: UIColor
            let qrBackgroundColor: UIColor
            let logoColor: UIColor
        }
        
        static private let lightTheme = Theme(
            backgroundColor: .white,
            qrBackgroundColor: .white,
            logoColor: .black
        )
        
        static private let darkTheme = Theme(
            backgroundColor: .black,
            qrBackgroundColor: .white,
            logoColor: .white
        )
        
        private func tokenIcon(urlString: String?) -> Single<UIImage?> {
            .create { single in
                if let urlString = urlString {
                    let url = NSURL(string: urlString)! as URL
                    if let imageData: NSData = NSData(contentsOf: url) {
                        single(.success(UIImage(data: imageData as Data)))
                    }
                }
                
                single(.success(nil))
                return Disposables.create {}
            }
        }
        
        private func qrCode(data: String) -> UIImage {
            let data = data.data(using: String.Encoding.ascii)
            
            if let filter = CIFilter(name: "CIQRCodeGenerator") {
                filter.setValue(data, forKey: "inputMessage")
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                
                if let output = filter.outputImage?.transformed(by: transform) {
                    let qrCode = UIImage(ciImage: output)
                    return qrCode
                }
            }
            return UIImage()
        }
        
        private func renderAsView(username: String?, address: String?, tokenImage: UIImage?) -> UIView {
            guard let address = address else {
                return UIView()
            }
            
            let style = UITraitCollection.current.userInterfaceStyle
            let theme = style == .light ? QrCodeImageRenderImpl.lightTheme : QrCodeImageRenderImpl.darkTheme
            
            return UIStackView(axis: .vertical, alignment: .fill) {
                
                // Username
                if username != nil {
                    UILabel(textSize: 20, weight: .semibold, numberOfLines: 2, textAlignment: .center).setupWithType(UILabel.self) { view in
                        let text = NSMutableAttributedString(string: username!.withNameServiceDomain())
                        text.addAttribute(.foregroundColor, value: UIColor.gray, range: NSRange(location: username!.count, length: text.length - username!.count))
                        view.attributedText = text
                    }.padding(.init(only: .top, inset: 26))
                }
                
                // Qr code
                BECenter {
                    BEZStack {
                        UIImageView(image: qrCode(data: address)).withTag(1)
                        UIImageView(width: 56, height: 56, image: tokenImage, contentMode: .scaleAspectFit)
                            .setup { view in
                                view.layer.borderWidth = 4
                                view.layer.borderColor = UIColor.textWhite.cgColor
                                view.layer.backgroundColor = UIColor.textWhite.cgColor
                                view.layer.cornerRadius = 28
                                view.layer.masksToBounds = true
                            }.withTag(2)
                    }.setup { view in
                            if let qrView = view.viewWithTag(1) { qrView.autoPinEdgesToSuperviewEdges() }
                            if let tokenView = view.viewWithTag(2) { tokenView.autoCenterInSuperview() }
                        }.frame(width: 238, height: 238)
                        .padding(.init(all: 16), backgroundColor: theme.qrBackgroundColor, cornerRadius: 8)
                }
                
                // Address
                UILabel(textSize: 15, weight: .semibold, numberOfLines: 5, textAlignment: .center)
                    .setupWithType(UILabel.self) { label in
                        let address = NSMutableAttributedString(string: address)
                        address.addAttribute(.foregroundColor, value: UIColor.h5887ff, range: NSRange(location: 0, length: 4))
                        address.addAttribute(.foregroundColor, value: UIColor.h5887ff, range: NSRange(location: address.length - 4, length: 4))
                        label.attributedText = address
                    }.padding(.init(top: 18, left: 48, bottom: 32, right: 48))
                
                // Logo
                UIImageView(image: .p2pValidatorLogo, tintColor: theme.logoColor)
                    .frame(width: 106, height: 36)
                    .centered(.horizontal)
                    .padding(.init(only: .bottom, inset: 19))
                
            }.frame(width: 340, height: 480)
                .backgroundColor(color: theme.backgroundColor)
        }
        
        func render(username: String?, address: String?, token: SolanaSDK.Token?) -> Single<UIImage> {
            guard let address = address else {
                return .just(UIImage())
            }
            
            return tokenIcon(urlString: token?.logoURI ?? SolanaSDK.Token.nativeSolana.logoURI).map { [unowned self] image in
                renderAsView(username: username, address: address, tokenImage: image).asImageInBackground()
            }
        }
    }
}
