//
//  UINavigationController+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/03/2021.
//

import Foundation

extension UINavigationController {
    override open var childForStatusBarStyle: UIViewController? {
        return topViewController
    }
}
