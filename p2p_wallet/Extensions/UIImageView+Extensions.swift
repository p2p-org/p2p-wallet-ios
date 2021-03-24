//
//  UIImageView+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/11/2020.
//

import Foundation
import SDWebImage

extension UIImageView {
    static let qrCodeCache = NSCache<NSString, UIImage>()
    
    func setImage(urlString: String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            image = UIColor.gray.image(frame.size)
            return
        }
        sd_setImage(with: url) { [weak self] (image, _, _, _) in
            if image == nil {
                self?.image = UIColor.gray.image(self?.frame.size ?? .zero)
            }
        }
    }
    
    func setQrCode(string: String?) {
        guard let string = string else {
            self.image = nil
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
                let transform = CGAffineTransform(scaleX: 3, y: 3)

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
    
    func with(urlString: String?) -> Self {
        setImage(urlString: urlString)
        return self
    }
    
    static var p2pValidatorLogo: UIImageView {
        UIImageView(width: 88, height: 31, image: .p2pValidatorLogo)
    }
}
