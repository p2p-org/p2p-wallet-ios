//
//  UIImageView+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/11/2020.
//

import Foundation
import SDWebImage
import CoreImage.CIFilterBuiltins

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
    
    func with(urlString: String?) -> Self {
        setImage(urlString: urlString)
        return self
    }
    
    static var p2pValidatorLogo: UIImageView {
        UIImageView(width: 88, height: 31, image: .p2pValidatorLogo)
    }
}
