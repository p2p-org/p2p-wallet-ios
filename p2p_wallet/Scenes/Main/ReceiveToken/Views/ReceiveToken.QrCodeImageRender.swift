//
// Created by Giang Long Tran on 08.01.22.
//

import Foundation
import BEPureLayout

protocol QrCodeImageRender {
    func render(username: String?, address: String?, token: SolanaSDK.Token?) -> UIImage
}

extension ReceiveToken {
    class QrCodeImageRenderImpl: QrCodeImageRender {
        func render(username: String?, address: String?, token: SolanaSDK.Token?) -> UIImage {
            guard let address = address else {
                return UIImage()
            }
            
            let qrCode = UILabel(text: username)
                //UIStackView(axis: .vertical, alignment: .fill) {
                    
                    // Username
                //    if username != nil {
                        UILabel(text: username)
               //     }
                    
                    // Qr code
//                    QrCodeView(size: 238, coinLogoSize: 44)
//                        .with(string: address, token: token)
//                        .autoAdjustWidthHeightRatio(1)
                    
                    // Address
//                    UILabel(textSize: 15, weight: .semibold, numberOfLines: 5, textAlignment: .center)
//                        .setupWithType(UILabel.self) { label in
//                            let address = NSMutableAttributedString(string: address)
//                            address.addAttribute(.foregroundColor, value: UIColor.h5887ff, range: NSRange(location: 0, length: 4))
//                            address.addAttribute(.foregroundColor, value: UIColor.h5887ff, range: NSRange(location: address.length - 4, length: 4))
//                            label.attributedText = address
//                        }.padding(.init(x: 50, y: 24))
                    
                    // Logo
//                    UIImageView(image: .p2pValidatorLogo)
                
            //}
            
            return qrCode.asImage()
        }
    }
}
