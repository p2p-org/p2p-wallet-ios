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
    var disposedBag = DisposeBag()
    var walletCellEditAction: Action<Wallet, Void>?
    
    init(
        index: Int,
        viewModel: WalletsRepository,
        header: BECollectionViewSectionHeaderLayout? = nil,
        footer: BECollectionViewSectionFooterLayout? = nil,
        background: UICollectionReusableView.Type? = nil,
        cellType: BECollectionViewCell.Type,
        numberOfLoadingCells: Int = 2,
        customFilter: @escaping ((AnyHashable) -> Bool) = { item in
            guard let wallet = item as? Wallet else {return false}
            return !wallet.isHidden
        },
        limit: Int? = nil
    ) {
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
    
    override func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: BECollectionViewItem) -> UICollectionViewCell {
        let cell = super.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
        
        if let cell = cell as? SwipeableCell {
            cell
                .onAction
                .emit(onNext: { [weak self] action in
                    guard let action = action as? NWalletCell.Action else { return }
                    switch action {
                    case .visible:
                        let viewModel = self?.viewModel as? WalletsRepository
                        viewModel?.toggleWalletVisibility(item.value as! Wallet)
                    case .send:
                        return
                    }
                })
                .disposed(by: disposedBag)
        }
        
        if let cell = cell as? EditableWalletCell {
            cell.editAction = CocoaAction { [weak self] in
                self?.walletCellEditAction?.execute(item.value as! Wallet)
                return .just(())
            }
            cell.hideAction = CocoaAction { [weak self] in
                let viewModel = self?.viewModel as? WalletsRepository
                viewModel?.toggleWalletVisibility(item.value as! Wallet)
                return .just(())
            }
        }
        
        return cell
    }
}
