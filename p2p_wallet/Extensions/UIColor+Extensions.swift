//
//  UIColor+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation

extension UIColor {
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }

    func onDarkMode(_ color: UIColor) -> UIColor {
        let lightColor = self
        return UIColor { trait in
            trait.userInterfaceStyle == .dark ? color : lightColor
        }
    }
}
