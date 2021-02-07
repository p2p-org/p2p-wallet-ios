//
//  _AddNewWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/02/2021.
//

import Foundation
import LazySubject
import Action

class _AddNewWalletVC: WalletsVC {
    init() {
        let viewModel = _AddNewWalletVM()
        super.init(viewModel: viewModel)
    }
    
    override func setUp() {
        super.setUp()
        
        // disable refreshing
        collectionView.refreshControl = nil
        collectionView.keyboardDismissMode = .onDrag
    }
    
    override var sections: [Section] {
        [
            Section(
                cellType: _AddNewWalletCell.self,
                contentInsets: .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            )
        ]
    }
    
    override func configureCell(collectionView: UICollectionView, indexPath: IndexPath, item: Wallet) -> UICollectionViewCell {
        let cell = super.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
        if let cell = cell as? _AddNewWalletCell, let wallet = itemAtIndexPath(indexPath)
        {
            cell.viewInBlockchainExplorerButton.rx.action = CocoaAction {_ in
                self.showWebsite(url: "https://explorer.solana.com/address/\(wallet.mintAddress)")
                return .just(())
            }
            
            cell.createWalletAction = createTokenAccountAction(newWallet: wallet)
            
            cell.setUp(feeSubject: (viewModel as! _AddNewWalletVM).feeSubject)
        }
        return cell
    }
    
    func createTokenAccountAction(newWallet: Wallet) -> CocoaAction {
        CocoaAction {
            let viewModel = self.viewModel as! _AddNewWalletVM
            
            // catching error
            if viewModel.feeSubject.value > (WalletsVM.ofCurrentUser.solWallet?.amount ?? 0)
            {
                viewModel.updateItem(where: {$0.mintAddress == newWallet.mintAddress}, transform: {
                    var wallet = $0
                    wallet.isBeingCreated = nil
                    wallet.creatingError = L10n.insufficientFunds
                    return wallet
                })
                return .just(())
            }
            
            // remove existing error
            viewModel.updateItem(where: {$0.mintAddress == newWallet.mintAddress}, transform: {
                var wallet = $0
                wallet.isBeingCreated = true
                wallet.creatingError = nil
                return wallet
            })
            
            // request
            return SolanaSDK.shared.createTokenAccount(mintAddress: newWallet.mintAddress)
//            return Single<(String, String)>.just(("", "")).delay(.seconds(5), scheduler: MainScheduler.instance)
//                .map {_ -> (String, String) in
//                    throw SolanaSDK.Error.other("example")
//                }
                .do(
                    afterSuccess: { (signature, newPubkey) in
                        // remove suggestion from the list
                        self.viewModel.removeItem(where: {$0.mintAddress == newWallet.mintAddress})
                        
                        // cancel search if search result is empty
                        if self.viewModel.searchResult?.isEmpty == true
                        {
                            (self.parent as? AddNewWalletVC)?.searchBar.clear()
                        }
                        
                        // process transaction
                        var newWallet = newWallet
                        newWallet.pubkey = newPubkey
                        newWallet.isProcessing = true
                        let transaction = Transaction(
                            signatureInfo: .init(signature: signature),
                            type: .createAccount,
                            amount: -(viewModel.feeSubject.value ?? 0),
                            symbol: "SOL",
                            status: .processing,
                            newWallet: newWallet
                        )
                        TransactionsManager.shared.process(transaction)
                        
                        // present wallet
                        self.present(WalletDetailVC(wallet: newWallet), animated: true, completion: nil)
                    },
                    afterError: { (error) in
                        viewModel.updateItem(where: {$0.mintAddress == newWallet.mintAddress}, transform: {
                            var wallet = $0
                            wallet.isBeingCreated = nil
                            wallet.creatingError = error.localizedDescription
                            return wallet
                        })
                    }
                )
                .map {_ in ()}
                .asObservable()
        }
    }
    
    override func itemDidSelect(_ item: Wallet) {
        parent?.view.endEditing(true)
        viewModel.updateItem(where: {item.mintAddress == $0.mintAddress}, transform: {
            var wallet = $0
            wallet.isExpanded = !(wallet.isExpanded ?? false)
            return wallet
        })
    }
}
