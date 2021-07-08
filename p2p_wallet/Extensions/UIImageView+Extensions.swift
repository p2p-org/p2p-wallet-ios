//
//  UIImageView+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/11/2020.
//

import Foundation
import Kingfisher
import CoreImage.CIFilterBuiltins

extension UIImageView {
    static let qrCodeCache = NSCache<NSString, UIImage>()
    
    func setImage(urlString: String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            image = UIColor.gray.image(frame.size)
            return
        }
        kf.setImage(with: url, placeholder: UIColor.gray.image(frame.size))
    }
    
    func with(urlString: String?) -> Self {
        setImage(urlString: urlString)
        return self
    }
    
    static var walletIntro: UIImageView {
        UIImageView(width: 90, height: 90, image: .walletIntro)
    }
}
