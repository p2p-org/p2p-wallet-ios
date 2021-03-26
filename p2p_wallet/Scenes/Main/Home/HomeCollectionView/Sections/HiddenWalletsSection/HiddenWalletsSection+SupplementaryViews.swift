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
}
