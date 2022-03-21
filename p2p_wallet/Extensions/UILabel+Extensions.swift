//
//  UILabel+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/11/2021.
//

import Foundation

extension UILabel {
    func setAttributeString(_ text: NSAttributedString) -> Self {
        attributedText = text
        return self
    }

    func semiboldTexts(_ texts: [String]) {
        let aStr = NSMutableAttributedString(string: text!)
        for text in texts {
            let range = NSString(string: self.text!).range(of: text)
            aStr.addAttribute(.font, value: UIFont.systemFont(ofSize: 15, weight: .semibold), range: range)
            aStr.addAttribute(.foregroundColor, value: UIColor.h5887ff, range: range)
        }
        attributedText = aStr
    }
}
