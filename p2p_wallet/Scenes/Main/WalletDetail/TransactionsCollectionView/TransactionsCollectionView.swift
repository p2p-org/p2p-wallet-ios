//
//  TransactionsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/03/2021.
//

import Foundation
import Action

class TransactionsCollectionView: CollectionView<Transaction, WalletDetailTransactionsVM> {
    var wallet: Wallet?
    var receiveAction: CocoaAction?
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        if indexPath.section == 0 {
            let header = header as! WDVCSectionHeaderView
            reloadHeader(header)
        }
        return header
    }
    
    func reloadHeader(_ header: WDVCSectionHeaderView) {
        if let wallet = wallet {
            header.setUp(wallet: wallet)
        }
        header.lineChartView
            .subscribed(to: viewModel.graphVM)
            .disposed(by: disposeBag)
        header.chartPicker.delegate = self
        header.scanQrCodeAction = receiveAction
    }
}

extension TransactionsCollectionView: HorizontalPickerDelegate {
    func picker(_ picker: HorizontalPicker, didSelectOptionAtIndex index: Int) {
        guard index < Period.allCases.count else {return}
        viewModel.graphVM.period = Period.allCases[index]
        viewModel.graphVM.reload()
    }
}
