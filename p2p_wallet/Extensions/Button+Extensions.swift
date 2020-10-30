//
//  Button+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import Action

extension Button {
    @discardableResult
    func withAction(_ cocoaAction: CocoaAction) -> Self {
        var button = self
        button.rx.action = cocoaAction
        return button
    }
}
