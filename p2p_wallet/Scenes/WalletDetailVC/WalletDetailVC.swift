//
//  WalletDetailVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import DiffableDataSources

class WalletDetailVC: CollectionVC<Transaction, TransactionCell> {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .normal(backgroundColor: .vcBackground) }
    let wallet: Wallet
    
    // MARK: - Initializer
    init(wallet: Wallet) {
        self.wallet = wallet
        super.init(viewModel: WalletTransactionsVM(wallet: wallet))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        title = wallet.name
        view.backgroundColor = .vcBackground
    }
    
    // MARK: - Layout
    override var sections: [Section] {
        [Section(
            headerViewClass: WDVCSectionHeaderView.self,
            headerTitle: L10n.activities,
            interGroupSpacing: 2,
            itemHeight: .absolute(71)
        )]
    }
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        if indexPath.section == 0 {
            let header = header as! WDVCSectionHeaderView
            header.setUp(wallet: wallet)
            PricesManager.shared.fetchHistoricalPrice(for: wallet.symbol, period: .month)
                .subscribe(onSuccess: {records in
                    header.setUp(prices: records)
                })
                .disposed(by: disposeBag)
        }
        return header
    }
    
    override func itemDidSelect(_ item: Transaction) {
        let vc = TransactionInfoVC(transaction: item)
        present(vc, animated: true, completion: nil)
    }
}
