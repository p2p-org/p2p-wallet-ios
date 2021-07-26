//
//  ChooseWallet.CollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/07/2021.
//

import Foundation
import BECollectionView

extension ChooseWallet {
    class CollectionView: BEDynamicSectionsCollectionView {
        init(viewModel: ViewModel) {
            super.init(
                viewModel: viewModel,
                mapDataToSections: { viewModel in
                    let wallets = viewModel.getData(type: Wallet.self)
                    let myWallets = wallets.filter {$0.pubkey != nil}
                    let otherWallets = wallets.filter {$0.pubkey == nil}
                    return [
                        .init(
                            userInfo: 0,
                            items: myWallets
                        ),
                        .init(
                            userInfo: 1,
                            items: otherWallets,
                            customLayout: BECollectionViewSectionLayout(
                                header: .init(viewClass: SecondSectionHeaderView.self),
                                cellType: OtherTokenCell.self,
                                interGroupSpacing: 16
                            )
                        )
                    ]
                },
                layout: BECollectionViewSectionLayout(
                    header: .init(viewClass: FirstSectionHeaderView.self),
                    cellType: Cell.self,
                    emptyCellType: WLEmptyCell.self,
                    interGroupSpacing: 16
                )
            )
        }
        
        override func mapDataToSnapshot() -> NSDiffableDataSourceSnapshot<AnyHashable, BECollectionViewItem> {
            // get snapshot to modify
            var snapshot = super.mapDataToSnapshot()
            
            // if firstSection isEmpty but secondSection is not, then remove EmptyCell
            if snapshot.sectionIdentifiers.contains(0) &&
                snapshot.sectionIdentifiers.contains(1)
            {
                if snapshot.isSectionEmpty(sectionIdentifier: 0) &&
                    !snapshot.isSectionEmpty(sectionIdentifier: 1)
                {
                    snapshot.deleteItems(snapshot.itemIdentifiers(inSection: 0))
                }
            }
            
            return snapshot
        }
        
        override func configureSectionHeaderView(view: UICollectionReusableView?, sectionIndex: Int) {
            if let view = view as? WLSectionHeaderView {
                if viewModel.getData(type: Wallet.self).count == 0 {
                    view.headerLabel.isHidden = true
                } else {
                    view.headerLabel.isHidden = false
                }
            }
        }
        
        override func configureCell(indexPath: IndexPath, item: BECollectionViewItem) -> UICollectionViewCell? {
            let cell = super.configureCell(indexPath: indexPath, item: item)
            if let cell = cell as? WLEmptyCell {
                cell.titleLabel.text = L10n.nothingFound
                cell.subtitleLabel.text = L10n.changeYourSearchPhrase
            }
            return cell
        }
    }
}
