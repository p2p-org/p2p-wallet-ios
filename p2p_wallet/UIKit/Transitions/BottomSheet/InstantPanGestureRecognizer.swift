//
//  InstantPanGestureRecognizer.swift
//  p2p_wallet
//
//  Created by Ivan on 19.08.2022.
//

import UIKit

class InstantPanGestureRecognizer: UIPanGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .began { return }
        super.touchesBegan(touches, with: event)
        state = .began
    }
}
