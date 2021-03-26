//
//  BaseHiddenWalletSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/03/2021.
//

import Foundation
import BECollectionView
import Action

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

class BaseHiddenWalletsSection: WalletsSection {
    var showHideHiddenWalletsAction: CocoaAction?
    
    override func configureHeader(indexPath: IndexPath) -> UICollectionReusableView? {
        let view = super.configureHeader(indexPath: indexPath)
        if let view = view as? HiddenWalletsSectionHeaderView {
            view.showHideHiddenWalletsAction = showHideHiddenWalletsAction
        }
        return view
    }
    
    override func mapDataToCollectionViewItems() -> [BECollectionViewItem] {
        let viewModel = self.viewModel as? WalletsListViewModelType
        if viewModel?.isHiddenWalletsShown.value == true {
            return super.mapDataToCollectionViewItems()
        } else {
            return []
        }
    }
    
    override func dataDidLoad() {
        super.dataDidLoad()
        let viewModel = self.viewModel as! WalletsListViewModelType
        if let headerView = self.headerView() as? HiddenWalletsSectionHeaderView {
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
    }
}
