//
//  MainFooterView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import Action

extension MainVC {
    class FirstSectionHeaderView: SectionHeaderView {
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
            
            stackView.constraintToSuperviewWithAttribute(.top)?.constant = 30
            stackView.constraintToSuperviewWithAttribute(.bottom)?.constant = -30
        }
        
        @objc func balancesOverviewDidTouch() {
            showAllBalancesAction?.execute()
        }
    }
    
    class FirstSectionFooterView: SectionFooterView {
        var showProductsAction: CocoaAction?
        
        lazy var buttonLabel = UILabel(text: L10n.allMyBalances, textSize: 17, weight: .medium)
        lazy var button: UIView = {
            let view = UIView(backgroundColor: .lightGrayBackground, cornerRadius: 12)
            view.row([
                buttonLabel,
                UIImageView(width: 8, height: 13, image: .nextArrow, tintColor: .secondary)
            ], padding: .init(x: 20, y: 16))
            return view
                .onTap(self, action: #selector(buttonDidTouch))
        }()
        
        override func commonInit() {
            super.commonInit()
            stackView.alignment = .fill
            stackView.addArrangedSubview(button.padding(.init(x: .defaultPadding, y: 30)))
        }
        
        @objc func buttonDidTouch() {
            showProductsAction?.execute()
        }
    }
}
