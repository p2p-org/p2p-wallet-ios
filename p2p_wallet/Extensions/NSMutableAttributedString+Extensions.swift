//
//  NSMutableAttributedString+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/12/2020.
//

import Foundation

extension NSMutableAttributedString {
    @discardableResult
    func text(_ text: String, size: CGFloat = 15, weight: UIFont.Weight = .regular, color: UIColor = .textBlack) -> NSMutableAttributedString {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color
        ]
        let normal = NSAttributedString(string: text, attributes: attrs)
        append(normal)
        return self
    }
}
