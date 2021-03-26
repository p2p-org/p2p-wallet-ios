//
//  HiddenWalletsSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/03/2021.
//

import Foundation
import BECollectionView
import Action

extension HomeCollectionView {
    class HomeHiddenWalletsSection: HiddenWalletsSection {
        var showAllProductsAction: CocoaAction?
        
        init(index: Int, viewModel: WalletsListViewModelType) {
            super.init(
                index: index,
                viewModel: viewModel,
                header: .init(
                    viewClass: HiddenWalletsSectionHeaderView.self
                ),
                footer: .init(
                    identifier: "HiddenWalletsSectionFooterView",
                    viewClass: FooterView.self
                ),
                background: BackgroundView.self,
                limit: 4
            )
        }
        
        override func configureFooter(indexPath: IndexPath) -> UICollectionReusableView? {
            let view = super.configureFooter(indexPath: indexPath) as? FooterView
            view?.showProductsAction = showAllProductsAction
            return view
        }
        
        override func dataDidLoad() {
            super.dataDidLoad()
            let viewModel = self.viewModel as! WalletsListViewModelType
            if let footerView = footerView() as? FooterView {
                if let topConstraint = footerView.button.constraintToSuperviewWithAttribute(.top)
                {
                    if !viewModel.hiddenWallets().isEmpty && !viewModel.isHiddenWalletsShown.value {
                        if topConstraint.constant != 0 {
                            topConstraint.constant = 0
                            footerView.setNeedsLayout()
                            collectionView?.relayout()
                        }
                    } else {
                        if topConstraint.constant != 30 {
                            topConstraint.constant = 30
                            footerView.setNeedsLayout()
                            collectionView?.relayout()
                        }
                    }
                }
            }
        }
    }
}
