//
//  WalletsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Foundation
import Action

protocol MyWalletsScenesFactory {
    func makeWalletDetailVC(wallet: Wallet) -> WalletDetailVC
    func makeAddNewTokenVC() -> AddNewWalletVC
    func makeTokenSettingsViewController(pubkey: String) -> TokenSettingsViewController
}

class MyWalletsVC: CollectionVC<Wallet> {
    let scenesFactory: MyWalletsScenesFactory
    init(viewModel: ListViewModel<Wallet>, sceneFactory: MyWalletsScenesFactory) {
        self.scenesFactory = sceneFactory
        super.init(viewModel: viewModel)
    }
    
    // MARK: - Delegate
    override func itemDidSelect(_ item: Wallet) {
        let vc = scenesFactory.makeWalletDetailVC(wallet: item)
        present(vc, animated: true, completion: nil)
    }
    
    override func setUpCell(cell: UICollectionViewCell, withItem item: Wallet) {
        super.setUpCell(cell: cell, withItem: item)
        (cell as? EditableWalletCell)?.editAction = CocoaAction {
            guard let pubkey = item.pubkey else {return .just(())}
            let vc = self.scenesFactory.makeTokenSettingsViewController(pubkey: pubkey)
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
        (cell as? EditableWalletCell)?.hideAction = CocoaAction {
            let walletsVM = (self.viewModel as? WalletsVM)
            if item.isHidden {
                walletsVM?.unhideWallet(item)
            } else {
                walletsVM?.hideWallet(item)
            }
            return .just(())
        }
    }
}
