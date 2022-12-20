//
//  UINavigationController+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/03/2021.
//

import Foundation

extension UINavigationController {
    override open var childForStatusBarStyle: UIViewController? {
        topViewController
    }

    func popToViewController(ofClass: AnyClass, animated: Bool) {
        if let vc = viewControllers.last(where: { $0.isKind(of: ofClass) }) {
            popToViewController(vc, animated: animated)
        }
    }
}

extension UINavigationController {
    // True if `hidesBottomBarWhenPushed` can be set to true, otherwise false.
    // Workaround for iOS 14 bug.
    var canHideBottomForNextPush: Bool {
        // There is a bug in iOS 14 that hides the bottom bar
        // when popping multiple navigation controllers from the stack,
        // and one of them has hidesBottomBarWhenPushed set to true.
        // https://developer.apple.com/forums/thread/660750
        guard #available(iOS 14, *) else {
            return true
        }
        return viewControllers.count == 1
    }
}
