//
//  WalletsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Foundation

protocol MyWalletsScenesFactory {
    func makeWalletDetailVC(wallet: Wallet) -> WalletDetailVC
    func makeAddNewTokenVC() -> AddNewWalletVC
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
}
