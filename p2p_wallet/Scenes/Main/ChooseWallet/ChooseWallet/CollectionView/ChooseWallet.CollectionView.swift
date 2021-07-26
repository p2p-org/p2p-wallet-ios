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
                    var sections = [SectionInfo]()
                    if myWallets.count > 0 {
                        sections.append(.init(
                            userInfo: 0,
                            items: myWallets
                        ))
                    }
                    if otherWallets.count > 0 {
                        sections.append(.init(
                            userInfo: 1,
                            items: otherWallets,
                            customLayout: BECollectionViewSectionLayout(
                                header: .init(viewClass: SecondSectionHeaderView.self),
                                cellType: OtherTokenCell.self,
                                interGroupSpacing: 16
                            )
                        ))
                    }
                    return sections
                },
                layout: BECollectionViewSectionLayout(
                    header: .init(viewClass: FirstSectionHeaderView.self),
                    cellType: Cell.self,
                    emptyCellType: WLEmptyCell.self,
                    interGroupSpacing: 16
                )
            )
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
