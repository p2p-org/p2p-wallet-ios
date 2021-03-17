//
//  TokenSettingsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/03/2021.
//

import Foundation
import Action

class TokenSettingsCollectionView: CollectionView<TokenSettings, TokenSettingsViewModel>, TokenSettingsCellDelegate {
    override func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: CollectionViewItem<TokenSettings>) -> UICollectionViewCell {
        let cell = super.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
        (cell as! TokenSettingsCell).delegate = self
        return cell
    }
    
    func tokenSettingsCellDidToggleVisibility(_ cell: TokenSettingsCell) {
        self.viewModel.toggleHideWallet()
    }
}
