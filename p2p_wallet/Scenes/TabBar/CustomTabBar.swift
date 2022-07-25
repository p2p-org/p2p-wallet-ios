//
//  CustomTabBar.swift
//  p2p_wallet
//
//  Created by Ivan on 09.07.2022.
//

import UIKit

final class CustomTabBar: UITabBar {
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size)
        size.height += 16
        return size
    }
}
