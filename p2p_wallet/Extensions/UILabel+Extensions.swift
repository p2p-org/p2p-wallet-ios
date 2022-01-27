//
//  UILabel+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/11/2021.
//

import Foundation

extension UILabel {
    func setAttributeString(_ text: NSAttributedString) -> Self {
        self.attributedText = text
        return self
    }
}
