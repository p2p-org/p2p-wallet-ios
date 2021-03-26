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
        lazy var avatarImageView = UIImageView(width: 30, height: 30, backgroundColor: .c4c4c4, cornerRadius: 15)
            .onTap(self, action: #selector(avatarImageViewDidTouch))
        lazy var activeStatusView = UIView(width: 8, height: 8, backgroundColor: .red, cornerRadius: 4)
            .onTap(self, action: #selector(avatarImageViewDidTouch))
        var openProfileAction: CocoaAction?
        
        override func commonInit() {
            super.commonInit()
            // remove all arranged subviews
            stackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
            
            // add header
            let headerView = UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill, arrangedSubviews: [
                avatarImageView,
                .spacer
            ])
            
            headerView.addSubview(activeStatusView)
            activeStatusView.autoPinEdge(.top, to: .top, of: avatarImageView)
            activeStatusView.autoPinEdge(.trailing, to: .trailing, of: avatarImageView)
            
            stackView.addArrangedSubview(headerView.padding(.init(x: 20, y: 0)))
        }
        
        @objc func avatarImageViewDidTouch() {
            openProfileAction?.execute()
        }
    }
    
    class BackgroundView: SectionBackgroundView {
        override func commonInit() {
            super.commonInit()
            backgroundColor = .h1b1b1b
        }
    }
}
