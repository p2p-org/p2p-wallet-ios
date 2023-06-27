//
//  ResizablePresentationController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/01/2021.
//

import Foundation

protocol ResizablePresentationController: UIPresentationController {
    func presentedViewDidSwipe(gestureRecognizer: UIPanGestureRecognizer)
}
