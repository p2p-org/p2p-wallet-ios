//
//  HiddenWalletsSection+SupplementaryViews.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/03/2021.
//

import Foundation
import Action

extension HiddenWalletsSection {
    class HeaderView: SectionHeaderView {
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
    
    class FooterView: SectionFooterView {
        var showProductsAction: CocoaAction?
        
        lazy var button: UIView = {
            let view = UIView(backgroundColor: UIColor.white.withAlphaComponent(0.1), cornerRadius: 12)
            view.row([
                UILabel(text: L10n.allMyTokens, textSize: 17, weight: .medium, textColor: .white),
                UIImageView(width: 8, height: 13, image: .nextArrow, tintColor: .textSecondary)
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
    
    class BackgroundView: SectionBackgroundView {
        override func commonInit() {
            super.commonInit()
            backgroundColor = .h1b1b1b
        }
    }
}
