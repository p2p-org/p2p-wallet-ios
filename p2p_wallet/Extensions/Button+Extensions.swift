//
//  Button+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import Action

extension UIButton {
    static func closeFill() -> UIButton {
        let button = UIButton(width: 43, height: 43)
        button.setImage(.closeFill, for: .normal)
        return button
    }
}
