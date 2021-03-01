//
//  TokenSettingsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/03/2021.
//

import Foundation
import Action

class TokenSettingsCollectionView: CollectionView<TokenSettings> {
    override func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: CollectionViewItem<TokenSettings>) -> UICollectionViewCell {
        let cell = super.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
        (cell as! TokenSettingsCell).toggleVisibilityAction = CocoaAction {
            (self.viewModel as! TokenSettingsViewModel).toggleHideWallet()
            return .just(())
        }
        return cell
    }
}
