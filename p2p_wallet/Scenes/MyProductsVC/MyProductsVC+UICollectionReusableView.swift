//
//  MyProductsVC+UICollectionReusableView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/12/2020.
//

import Foundation
import Action

extension MyProductsVC {
    
    class FirstSectionHeaderView: SectionHeaderView {
        var addCoinAction: CocoaAction?
        
        override func commonInit() {
            super.commonInit()
            headerLabel.removeFromSuperview()
            
            let totalBalanceView = UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill, arrangedSubviews: [
                UIView.col([
                    UILabel(text: L10n.totalBalance, textSize: 15),
                    UILabel(text: "12 000$", textSize: 21, weight: .bold),
                    UILabel(text: "+3.5 \(L10n.forTheLast24Hour)", textSize: 13)
                ]),
                UIImageView(width: 75, height: 75, image: .totalBalanceGraph)
            ])
                .padding(.init(x: 16, y: 14), backgroundColor: .white, cornerRadius: 12)
            
            totalBalanceView.widthAnchor.constraint(greaterThanOrEqualToConstant: 335)
                .isActive = true
            
            totalBalanceView.addShadow(ofColor: UIColor.black.withAlphaComponent(0.07), radius: 24, offset: CGSize(width: 0, height: 4), opacity: 1)
            
            stackView.addArrangedSubviews([
                UIView.row([
                    UILabel(text: L10n.allMyProducts, textSize: 21, weight: .semibold),
                    UIImageView(width: 24, height: 24, image: .walletAdd, tintColor: .h5887ff)
                        .padding(.init(all: 10), backgroundColor: .eff3ff, cornerRadius: 12)
                        .onTap(self, action: #selector(buttonAddCoinDidTouch))
                ])
                    .padding(.init(x: .defaultPadding, y: 0)),
                totalBalanceView
                    .padding(.init(x: .defaultPadding, y: 0)),
                headerLabel
                    .padding(.init(x: .defaultPadding, y: 0))
            ], withCustomSpacings: [20, 32])
        }
        
        @objc func buttonAddCoinDidTouch() {
            addCoinAction?.execute()
        }
    }
}
