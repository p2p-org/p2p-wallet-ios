//
//  ActiveWalletsSection+SupplementaryViews.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/03/2021.
//

import Foundation
import Action

extension HomeCollectionView.ActiveWalletsSection {
    class HeaderView: SectionHeaderView {
        var showAllBalancesAction: CocoaAction?
        
        lazy var balancesOverviewView = BalancesOverviewView()
            .onTap(self, action: #selector(balancesOverviewDidTouch))
        
        override func commonInit() {
            super.commonInit()
            // remove all arranged subviews
            stackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
            
            // add header
            stackView.addArrangedSubviews([
                balancesOverviewView
                    .padding(.init(x: .defaultPadding, y: 0))
            ])
            
            stackView.constraintToSuperviewWithAttribute(.top)?.constant = 20
            stackView.constraintToSuperviewWithAttribute(.bottom)?.constant = -30
        }
        
        @objc func balancesOverviewDidTouch() {
            showAllBalancesAction?.execute()
        }
    }
}
