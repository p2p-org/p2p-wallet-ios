//
//  HomeWalletsSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/03/2021.
//

import Foundation
import BECollectionView
import Action
import RxSwift

class WalletsSection: BEStaticSectionsCollectionView.Section {
    
    class Header: BECollectionCell {
        override func build() -> UIView {
            UILabel(text: L10n.tokens, textSize: 13, weight: .medium, textColor: .secondaryLabel)
                .frame(height: 18)
                .padding(.init(only: .left, inset: 18))
                .padding(.init(only: .bottom, inset: 18))
        }
    }
    
    var walletCellEditAction: Action<Wallet, Void>?
    var onSend: BECallback<Wallet>?
    
    init(
        index: Int,
        viewModel: WalletsRepository,
        header: BECollectionViewSectionHeaderLayout? = nil,
        footer: BECollectionViewSectionFooterLayout? = nil,
        background: UICollectionReusableView.Type? = nil,
        cellType: BECollectionViewCell.Type,
        numberOfLoadingCells: Int = 2,
        customFilter: @escaping (AnyHashable) -> Bool = { item in
            guard let wallet = item as? Wallet else { return false }
            return !wallet.isHidden
        },
        onSend: BECallback<Wallet>? = nil,
        limit: Int? = nil
    ) {
        self.onSend = onSend
        
        super.init(
            index: index,
            layout: .init(
                header: header,
                footer: footer,
                cellType: cellType,
                numberOfLoadingCells: numberOfLoadingCells,
                interGroupSpacing: 0,
                itemHeight: .estimated(45),
                contentInsets: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                horizontalInterItemSpacing: .fixed(0),
                background: background
            ),
            viewModel: viewModel,
            customFilter: customFilter,
            limit: {
                if let limit = limit {
                    return Array($0.prefix(limit))
                }
                return $0
            }
        )
    }
    
    override func configureCell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        item: BECollectionViewItem
    ) -> UICollectionViewCell {
        let cell = super.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
        
        if let cell = cell as? VisibleWalletCell {
            cell.onSend = { [weak self] in
                self?.onSend?((item.value as! Wallet))
            }
            
            cell.onHide = { [weak self] in
                let viewModel = self?.viewModel as? WalletsRepository
                viewModel?.toggleWalletVisibility(item.value as! Wallet)
            }
        }
        
        if let cell = cell as? HidedWalletCell {
            cell.onSend = { [weak self] in
                self?.onSend?((item.value as! Wallet))
            }
            
            cell.onShow = { [weak self] in
                let viewModel = self?.viewModel as? WalletsRepository
                viewModel?.toggleWalletVisibility(item.value as! Wallet)
            }
        }
        
        return cell
    }
}
