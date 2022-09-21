//
//  Button+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Action
import Foundation
import KeyAppUI

extension UIButton {
    static func closeFill() -> UIButton {
        let button = UIButton(width: 43, height: 43)
        button.setImage(.closeFill, for: .normal)
        return button
    }

    static func close() -> UIButton {
        let button = UIButton(width: 43, height: 43)
        button.setImage(.closeBanner, for: .normal)
        button.tintColor = Asset.Colors.night.color
        return button
    }
}
