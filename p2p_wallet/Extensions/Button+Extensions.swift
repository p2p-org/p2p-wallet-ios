//
//  Button+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Action
import Foundation

extension UIButton {
    @discardableResult
    func withAction(_ cocoaAction: CocoaAction) -> Self {
        var button = self
        button.rx.action = cocoaAction
        return button
    }

    static func close(tintColor: UIColor = .textBlack) -> UIButton {
        let button = UIButton(width: 43, height: 43)
        button.setImage(.close, for: .normal)
        button.tintColor = tintColor
        return button
    }

    static func closeFill() -> UIButton {
        let button = UIButton(width: 43, height: 43)
        button.setImage(.closeFill, for: .normal)
        return button
    }
}
