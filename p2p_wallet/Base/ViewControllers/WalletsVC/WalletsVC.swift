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
    
}

class MyWalletsVC<WalletCell: WalletCellType>: WalletsVC<WalletCell> {
    
    init() {
        let viewModel = WalletsVM.ofCurrentUser
        super.init(viewModel: viewModel)
    }
    
    override func bind() {
        super.bind()
        TransactionsManager.shared.transactions
            .map {$0.filter {$0.type == .createAccount && $0.newWallet != nil}}
            .filter {$0.count > 0}
            .subscribe(onNext: { transactions in
                let newWallets = transactions.compactMap({$0.newWallet})
                var wallets = self.viewModel.items
                for wallet in newWallets {
                    if !wallets.contains(where: {$0.pubkey == wallet.pubkey}) {
                        wallets.append(wallet)
                    } else {
                        self.viewModel.updateItem(where: {$0.pubkey == wallet.pubkey}) { oldWallet in
                            var newWallet = oldWallet
                            newWallet.isProcessing = wallet.isProcessing
                            return newWallet
                        }
                    }
                }
                
                if wallets.count > 0 {
                    self.viewModel.items = wallets
                    self.viewModel.state.accept(.loaded(wallets))
                }
            })
            .disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Delegate
    override func itemDidSelect(_ item: Wallet) {
        present(WalletDetailVC(wallet: item), animated: true, completion: nil)
    }
}
