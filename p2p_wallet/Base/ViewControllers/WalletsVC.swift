//
//  WalletsVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Foundation

protocol WalletCellType: CollectionCell {
    func setUp(with item: Wallet)
}
class WalletsVC<WalletCell: WalletCellType>: CollectionVC<Wallet, WalletCell> {
    init() {
        let viewModel = WalletVM.ofCurrentUser
        super.init(viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
