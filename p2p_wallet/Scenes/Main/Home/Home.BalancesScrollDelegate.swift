//
//  Home.BalancesScrollDelegate.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 24.11.2021.
//

import UIKit
import BEPureLayout

extension Home {
    final class HeaderScrollDelegate: NSObject, UIScrollViewDelegate {
        var headerView: FloatingHeaderView?
        
        init(headerView: FloatingHeaderView? = nil) {
            self.headerView = headerView
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard let headerView = headerView else { return }
            let maxValue = headerView.preferredTopHeight + headerView.bottomMaxHeight
            let offset = (scrollView.contentOffset.y + scrollView.contentInset.top)
            let value = min(max(offset, 0), maxValue)
            
            print([value.truncatingRemainder(dividingBy: 2)])
            
            guard value > 0 else {
                headerView.collapseConstraint.constant = 0
                headerView.bottomCollapseConstraint.constant = headerView.bottomMaxHeight
                return
            }
            
            if (value < headerView.preferredTopHeight) {
                // collapse top
                headerView.collapseConstraint.constant = value
            } else {
                // collapse bottom
                let bottomValue = headerView.bottomMaxHeight - (value - headerView.preferredTopHeight)
                print("=== \(bottomValue)")
                headerView.bottomCollapseConstraint.constant = min(max(headerView.bottomMinHeight, bottomValue), headerView.bottomMaxHeight)
            }
            
            
        }
    }
}
