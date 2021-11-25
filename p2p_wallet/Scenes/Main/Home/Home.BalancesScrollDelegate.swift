//
//  Home.BalancesScrollDelegate.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 24.11.2021.
//

import UIKit
import BEPureLayout

extension Home {
    final class BalancesScrollDelegate: NSObject, UIScrollViewDelegate {
        private let balancesView: BERoundedCornerShadowView

        init(balancesView: BERoundedCornerShadowView) {
            self.balancesView = balancesView
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            balancesView.topStackConstraint.constant = -scrollView.contentOffset.y
            balancesView.superview?.layoutIfNeeded()
        }
    }
}
