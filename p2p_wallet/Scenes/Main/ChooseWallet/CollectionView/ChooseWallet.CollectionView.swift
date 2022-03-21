//
//  ChooseWallet.CollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/07/2021.
//

import BECollectionView
import Foundation

extension ChooseWallet {
    class CollectionView: BEDynamicSectionsCollectionView {
        private let specificViewModel: ViewModel

        init(viewModel: ViewModel) {
            specificViewModel = viewModel

            super.init(
                viewModel: viewModel,
                mapDataToSections: { viewModel in
                    let wallets = viewModel.getData(type: Wallet.self)
                    let myWallets = wallets.filter { $0.pubkey != nil }
                    let otherWallets = wallets.filter { $0.pubkey == nil }
                    var sections = [SectionInfo]()
                    if !myWallets.isEmpty {
                        sections.append(.init(
                            userInfo: 0,
                            items: myWallets
                        ))
                    }
                    if !otherWallets.isEmpty {
                        sections.append(.init(
                            userInfo: 1,
                            items: otherWallets,
                            customLayout: BECollectionViewSectionLayout(
                                cellType: OtherTokenCell.self,
                                interGroupSpacing: 8
                            )
                        ))
                    }
                    return sections
                },
                layout: BECollectionViewSectionLayout(
                    cellType: Cell.self,
                    emptyCellType: WLEmptyCell.self,
                    interGroupSpacing: 8
                )
            )
        }

        override func configureCell(indexPath: IndexPath, item: BECollectionViewItem) -> UICollectionViewCell? {
            let cell = super.configureCell(indexPath: indexPath, item: item)

            if
                let cell = cell as? WalletCell,
                let wallet = dataSource.itemIdentifier(for: indexPath)?.value as? Wallet
            {
                let isSelected = wallet.token == specificViewModel.selectedWallet?.token
                cell.setIsSelected(isSelected: isSelected)
            }

            if let cell = cell as? WLEmptyCell {
                cell.titleLabel.text = L10n.nothingFound
                cell.subtitleLabel.text = L10n.changeYourSearchPhrase
            }
            return cell
        }
    }
}
