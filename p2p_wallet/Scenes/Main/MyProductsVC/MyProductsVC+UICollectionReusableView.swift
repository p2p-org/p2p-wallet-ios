//
//  MyProductsVC+UICollectionReusableView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/12/2020.
//

import Foundation
import Action

extension _MyProductsVC {
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
    
    class HiddenWalletsSectionHeaderView: SectionHeaderView {
        var showHideHiddenWalletsAction: CocoaAction?
        override func commonInit() {
            super.commonInit()
            stackView.axis = .horizontal
            stackView.distribution = .fill
            stackView.alignment = .center
            let imageView = UIImageView(width: 20, height: 20, image: .visibilityShow, tintColor: .textSecondary)
                .padding(.init(all: 12.5))
                .padding(.init(top: 10, left: .defaultPadding, bottom: 10, right: 0))
            stackView.insertArrangedSubview(
                imageView,
                at: 0
            )
            
            headerLabel.alpha = 0.5
            
            stackView.isUserInteractionEnabled = true
            stackView.onTap(self, action: #selector(stackViewDidTouch))
        }
        
        @objc func stackViewDidTouch() {
            showHideHiddenWalletsAction?.execute()
        }
    }
}
