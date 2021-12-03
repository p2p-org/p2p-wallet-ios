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
        private let balancesView: BalancesOverviewView

        init(balancesView: BalancesOverviewView) {
            self.balancesView = balancesView
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            balancesView.topStackConstraint.constant = -(scrollView.contentOffset.y + scrollView.contentInset.top)
        }
    }
}
