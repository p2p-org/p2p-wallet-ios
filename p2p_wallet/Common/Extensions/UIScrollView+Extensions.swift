//
//  UIScrollView+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/07/2021.
//

import Foundation
extension UIScrollView {
    func scrollToBottom(animated: Bool) {
        scrollTo(y: contentSize.height - bounds.size.height + contentInset.bottom, animated: animated)
    }

    func scrollTo(y: CGFloat, animated: Bool) {
        if contentSize.height < bounds.size.height { return }
        let bottomOffset = CGPoint(x: 0, y: y)
        if bottomOffset == contentOffset { return }
        var newValue = bottomOffset
        let maxY = contentSize.height - bounds.size.height + contentInset.bottom // bottom
        if newValue.y > maxY {
            newValue = CGPoint(x: 0, y: maxY)
        }
        setContentOffset(newValue, animated: animated)
    }
}
