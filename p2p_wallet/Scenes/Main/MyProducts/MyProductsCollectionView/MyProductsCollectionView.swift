//
//  MyProductsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/03/2021.
//

import Foundation
import Action

class MyProductsCollectionView: WalletsCollectionView {
    init(viewModel: WalletsVM) {
        super.init(viewModel: viewModel, sections: [
            CollectionViewSection(
                header: CollectionViewSection.Header(viewClass: FirstSectionHeaderView.self, title: L10n.balances, titleFont: .systemFont(ofSize: 17, weight: .semibold)),
                cellType: HomeWalletCell.self,
                interGroupSpacing: 30,
                itemHeight: .estimated(45),
                horizontalInterItemSpacing: NSCollectionLayoutSpacing.fixed(16)
            ),
            CollectionViewSection(
                header: CollectionViewSection.Header(
                    viewClass: HiddenWalletsSectionHeaderView.self, title: L10n.hiddenWallets
                ),
                cellType: HomeWalletCell.self,
                interGroupSpacing: 30,
                itemHeight: .absolute(45),
                horizontalInterItemSpacing: NSCollectionLayoutSpacing.fixed(16)
            )
        ])
    }
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        switch indexPath.section {
        case 0:
            if let view = header as? FirstSectionHeaderView {
                view.balancesOverviewView.setUp(with: viewModel.state.value)
            }
        case 1:
            if let view = header as? HiddenWalletsSectionHeaderView {
                setUpHeaderForHiddenWalletsSection(view)
                view.showHideHiddenWalletsAction = CocoaAction { [weak self] in
                    self?.viewModel.toggleIsHiddenWalletShown()
                    return .just(())
                }
            }
        default:
            break
        }
        return header
    }
    
    override func dataDidLoad() {
        super.dataDidLoad()
        // fix header
        if let headerView = headerForSection(0) as? FirstSectionHeaderView
        {
            headerView.balancesOverviewView.setUp(with: viewModel.state.value)
        }
        
        if let headerView = headerForSection(1) as? HiddenWalletsSectionHeaderView {
            setUpHeaderForHiddenWalletsSection(headerView)
        }
    }
    
    private func setUpHeaderForHiddenWalletsSection(_ headerView: HiddenWalletsSectionHeaderView) {
        if viewModel.isHiddenWalletsShown.value {
            headerView.imageView.tintColor = .textBlack
            headerView.imageView.image = .visibilityHide
            headerView.headerLabel.textColor = .textBlack
            headerView.headerLabel.text = L10n.hide
        } else {
            headerView.imageView.tintColor = .textSecondary
            headerView.imageView.image = .visibilityShow
            headerView.headerLabel.textColor = .textSecondary
            headerView.headerLabel.text = L10n.dHiddenWallet(viewModel.hiddenWallets().count)
        }
        if viewModel.hiddenWallets().isEmpty {
            headerView.removeStackView {
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
        } else {
            headerView.addStackView {
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
        }
    }
}
