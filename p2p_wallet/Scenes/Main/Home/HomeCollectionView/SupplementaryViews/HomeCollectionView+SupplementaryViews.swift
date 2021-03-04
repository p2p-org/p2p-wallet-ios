//
//  HomeCollectionView+SupplementaryViews.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/03/2021.
//

import Foundation
import Action

extension HomeCollectionView {
    class ActiveWalletsSectionHeaderView: SectionHeaderView {
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
    
    class HiddenWalletsSectionHeaderView: SectionHeaderView {
        var showHideHiddenWalletsAction: CocoaAction?
        
        lazy var imageView = UIImageView(width: 20, height: 20, image: .visibilityShow, tintColor: .textSecondary)
        
        override func layoutSubviews() {
            super.layoutSubviews()
            headerLabel.font = .systemFont(ofSize: 15)
        }
        
        override func commonInit() {
            super.commonInit()
            stackView.axis = .horizontal
            stackView.distribution = .fill
            stackView.alignment = .center
            
            headerLabel.wrapper?.removeFromSuperview()
            stackView.addArrangedSubviews([
                imageView
                    .padding(.init(all: 12.5))
                    .padding(.init(top: 10, left: .defaultPadding, bottom: 10, right: 0))
                ,
                headerLabel
            ])
            
            stackView.isUserInteractionEnabled = true
            stackView.onTap(self, action: #selector(stackViewDidTouch))
        }
        
        @objc func stackViewDidTouch() {
            showHideHiddenWalletsAction?.execute()
        }
    }
    
    class WalletsSectionFooterView: SectionFooterView {
        var showProductsAction: CocoaAction?
        
        lazy var buttonLabel = UILabel(text: L10n.allMyTokens, textSize: 17, weight: .medium)
        lazy var indicatorImageView = UIImageView(width: 24, height: 24, image: .indicatorNext, tintColor: .textSecondary)
        
        lazy var button: UIView = {
            let view = UIView(backgroundColor: .lightGrayBackground, cornerRadius: 12)
            view.row([
                buttonLabel,
                indicatorImageView
            ], padding: .init(x: 20, y: 16))
            return view
                .onTap(self, action: #selector(buttonDidTouch))
        }()
        
        override func commonInit() {
            super.commonInit()
            stackView.alignment = .fill
            stackView.addArrangedSubview(button.padding(.init(x: .defaultPadding, y: 30)))
        }
        
        func setUp(title: String, indicator: UIImage, action: CocoaAction?)
        {
            setUp(state: .loaded(title), isListEmpty: false)
            buttonLabel.text = title
            indicatorImageView.image = indicator
            showProductsAction = action
        }
        
        @objc func buttonDidTouch() {
            showProductsAction?.execute()
        }
    }
}
