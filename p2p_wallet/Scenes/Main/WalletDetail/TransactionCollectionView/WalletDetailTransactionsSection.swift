//
//  WalletDetailTransactionsSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation
import BECollectionView
import RxSwift
import Action

class WalletDetailTransactionsSection: BECollectionViewSection {
    var wallet: Wallet?
    let disposeBag = DisposeBag()
    let graphViewModel: WalletGraphVM
    var scanQrCodeAction: CocoaAction?
    
    init(
        index: Int,
        viewModel: BEListViewModelType,
        graphViewModel: WalletGraphVM
    ) {
        self.graphViewModel = graphViewModel
        super.init(
            index: index,
            layout: .init(
                header: .init(
                    viewClass: WDVCSectionHeaderView.self
                ),
                cellType: TransactionCell.self,
                interGroupSpacing: 1,
                itemHeight: .estimated(85)
            ),
            viewModel: viewModel
        )
    }
    
    override func configureHeader(indexPath: IndexPath) -> UICollectionReusableView? {
        let header = super.configureHeader(indexPath: indexPath)
        reloadHeader(header: header)
        return header
    }
    
    func reloadHeader(header: UICollectionReusableView? = nil) {
        if let header = (header ?? self.headerView()) as? WDVCSectionHeaderView {
            header.headerLabel.text = L10n.activities
            if let wallet = wallet {
                header.setUp(wallet: wallet)
            }
            header.lineChartView
                .subscribed(to: graphViewModel)
                .disposed(by: disposeBag)
            header.chartPicker.delegate = self
            header.scanQrCodeAction = scanQrCodeAction
        }
    }
}

extension WalletDetailTransactionsSection: HorizontalPickerDelegate {
    func picker(_ picker: HorizontalPicker, didSelectOptionAtIndex index: Int) {
        guard index < Period.allCases.count else {return}
        graphViewModel.period = Period.allCases[index]
        graphViewModel.reload()
    }
}
