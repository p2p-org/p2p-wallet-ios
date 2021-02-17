//
//  _AddNewWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/02/2021.
//

import Foundation
import LazySubject
import Action

class _AddNewWalletVC: CollectionVC<Wallet> {
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
    
    override func bind() {
        super.bind()
        let viewModel = self.viewModel as! _AddNewWalletVM
        
        viewModel.navigatorSubject
            .subscribe(onNext: {navigator in
                switch navigator {
                case .present(let vc):
                    self.present(vc, animated: true, completion: nil)
                case .show(let vc):
                    self.show(vc, sender: nil)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.clearSearchBarSubject
            .subscribe(onNext: {
                (self.parent as? AddNewWalletVC)?.searchBar.clear()
            })
            .disposed(by: disposeBag)
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
        let viewModel = self.viewModel as! _AddNewWalletVM
        if let cell = cell as? _AddNewWalletCell, let wallet = itemAtIndexPath(indexPath)
        {
            cell.viewInBlockchainExplorerButton.rx.action = CocoaAction {_ in
                self.showWebsite(url: "https://explorer.solana.com/address/\(wallet.mintAddress)")
                return .just(())
            }
            
            cell.createWalletAction = viewModel.addNewToken(newWallet: wallet)
            cell.setUp(feeSubject: viewModel.feeSubject)
        }
        return cell
    }
    
    override func itemDidSelect(_ item: Wallet) {
        parent?.view.endEditing(true)
        (viewModel as! _AddNewWalletVM).tokenDidSelect(item)
    }
}
