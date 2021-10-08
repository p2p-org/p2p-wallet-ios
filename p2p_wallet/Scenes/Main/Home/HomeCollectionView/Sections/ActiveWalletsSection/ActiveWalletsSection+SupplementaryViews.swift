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
        private lazy var avatarImageView = UIImageView(width: 30, height: 30, backgroundColor: .c4c4c4, cornerRadius: 15)
            .onTap(self, action: #selector(avatarImageViewDidTouch))
        private lazy var activeStatusView = UIView(width: 8, height: 8, backgroundColor: .red, cornerRadius: 4)
            .onTap(self, action: #selector(avatarImageViewDidTouch))
        var openProfileAction: CocoaAction?
        var reserveNameAction: CocoaAction?
        
        private lazy var bannerView: WLBannerView = {
            let bannerView = WLBannerView(
                title: L10n.reserveYourP2PUsernameNow,
                description: L10n.anyTokenCanBeReceivedUsingUsernameRegardlessOfWhetherItIsInYourWalletsList
            )
                .onTap(self, action: #selector(bannerDidTouch))
            bannerView.closeButtonCompletion = {
                Defaults.forceCloseNameServiceBanner = true
            }
            return bannerView
        }()
        
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
            stackView.addArrangedSubview(bannerView.padding(.init(x: 20, y: 0)))
            
            setHideBanner(true)
        }
        
        func setHideBanner(_ isHidden: Bool) {
            bannerView.superview!.isHidden = isHidden
        }
        
        @objc func avatarImageViewDidTouch() {
            openProfileAction?.execute()
        }
        
        @objc func bannerDidTouch() {
            reserveNameAction?.execute()
        }
    }
    
    class BackgroundView: SectionBackgroundView {
        override func commonInit() {
            super.commonInit()
            backgroundColor = .h1b1b1b
        }
    }
}
