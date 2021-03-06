//
//  MyProductsCollectionView+SupplementaryViews.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/03/2021.
//

import Foundation
import Action

extension MyProductsCollectionView {
    class FirstSectionHeaderView: SectionHeaderView {
        lazy var balancesOverviewView = BalancesOverviewView()
        
        override func commonInit() {
            super.commonInit()
            headerLabel.removeFromSuperview()
            
            balancesOverviewView.widthAnchor.constraint(greaterThanOrEqualToConstant: 335)
                .isActive = true
            
            stackView.addArrangedSubviews([
                balancesOverviewView
                    .padding(.init(x: .defaultPadding, y: 0)),
                BEStackViewSpacing(32),
                headerLabel
                    .padding(.init(x: .defaultPadding, y: 0))
            ])
            
            stackView.constraintToSuperviewWithAttribute(.bottom)?.constant = -32
            
            layoutSubviews()
        }
    }
}
