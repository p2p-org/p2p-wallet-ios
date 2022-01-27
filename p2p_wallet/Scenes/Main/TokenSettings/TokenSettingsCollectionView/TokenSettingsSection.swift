//
//  TokenSettingsSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/03/2021.
//

import Foundation
import Action
import BECollectionView

class TokenSettingsSection: BEStaticSectionsCollectionView.Section {
    override func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: BECollectionViewItem) -> UICollectionViewCell {
        let cell = super.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
        (cell as? TokenSettingsCell)?.delegate = self
        return cell
    }
}

extension TokenSettingsSection: TokenSettingsCellDelegate {
    func tokenSettingsCellDidToggleVisibility(_: TokenSettingsCell) {
        (self.viewModel as? TokenSettingsViewModel)?.toggleHideWallet()
    }
}
