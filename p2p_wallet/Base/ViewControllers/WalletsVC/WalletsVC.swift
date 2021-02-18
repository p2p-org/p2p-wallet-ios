//
//  WalletsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Foundation

class MyWalletsVC: CollectionVC<Wallet> {
    
    // MARK: - Delegate
    override func itemDidSelect(_ item: Wallet) {
        let vc = DependencyContainer.shared.makeWalletDetailVC(wallet: item)
        present(vc, animated: true, completion: nil)
    }
}
