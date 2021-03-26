//
//  HiddenWalletsSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 25/03/2021.
//

import Foundation
import BECollectionView
import Action

class HiddenWalletsSection: BECollectionViewSection {
    var showAllProductsAction: CocoaAction?
    var showHideHiddenWalletsAction: CocoaAction?
    var walletCellEditAction: Action<Wallet, Void>?
    
    init(index: Int, viewModel: WalletsListViewModelType) {
        super.init(
            index: index,
            layout: .init(
                header: .init(
                    identifier: "HiddenWalletsSectionHeaderView",
                    viewClass: HeaderView.self
                ),
                footer: .init(
                    identifier: "HiddenWalletsSectionFooterView",
                    viewClass: FooterView.self
                ),
                cellType: HomeWalletCell.self,
                interGroupSpacing: 30,
                itemHeight: .absolute(45),
                contentInsets: NSDirectionalEdgeInsets(top: 0, leading: .defaultPadding, bottom: .defaultPadding, trailing: .defaultPadding),
                horizontalInterItemSpacing: .fixed(16),
                background: BackgroundView.self
            ),
            viewModel: viewModel,
            customFilter: { item in
                guard let wallet = item as? Wallet else {return false}
                return wallet.isHidden
            },
            limit: {
                Array($0.prefix(4))
            }
        )
    }
    
    override func configureHeader(indexPath: IndexPath) -> UICollectionReusableView? {
        let view = super.configureHeader(indexPath: indexPath) as? HeaderView
        view?.showHideHiddenWalletsAction = showHideHiddenWalletsAction
        return view
    }
    
    override func configureFooter(indexPath: IndexPath) -> UICollectionReusableView? {
        let view = super.configureFooter(indexPath: indexPath) as? FooterView
        view?.showProductsAction = showAllProductsAction
        return view
    }
    
    override func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: BECollectionViewItem) -> BECollectionViewCell {
        let cell = super.configureCell(collectionView: collectionView, indexPath: indexPath, item: item) as! HomeWalletCell
        cell.editAction = CocoaAction { [weak self] in
            self?.walletCellEditAction?.execute(item.value as! Wallet)
            return .just(())
        }
        cell.hideAction = CocoaAction { [weak self] in
            let viewModel = self?.viewModel as? WalletsListViewModelType
            viewModel?.toggleWalletVisibility(item.value as! Wallet)
            return .just(())
        }
        return cell
    }
    
    override func dataDidLoad() {
        super.dataDidLoad()
        let viewModel = self.viewModel as! WalletsListViewModelType
        if let headerView = self.headerView() as? HeaderView {
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
                headerView.removeStackView { [weak self] in
                    self?.collectionViewLayout?.invalidateLayout()
                }
            } else {
                headerView.addStackView { [weak self] in
                    self?.collectionViewLayout?.invalidateLayout()
                }
            }
        }

        if let footerView = footerView() as? FooterView {
            if let topConstraint = footerView.button.constraintToSuperviewWithAttribute(.top)
            {
                if !viewModel.hiddenWallets().isEmpty && !viewModel.isHiddenWalletsShown.value {
                    if topConstraint.constant != 0 {
                        topConstraint.constant = 0
                        footerView.setNeedsLayout()
                        collectionViewLayout?.invalidateLayout()
                    }
                } else {
                    if topConstraint.constant != 30 {
                        topConstraint.constant = 30
                        footerView.setNeedsLayout()
                        collectionViewLayout?.invalidateLayout()
                    }
                }
            }
        }
    }
}
