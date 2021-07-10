//
//  TransactionsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation
import BECollectionView
import Action
import RxCocoa

class TransactionsCollectionView: BEDynamicSectionsCollectionView {
    let graphViewModel: WalletGraphViewModel
    let analyticsManager: AnalyticsManagerType
    let scanQrCodeAction: CocoaAction
    let wallet: Driver<Wallet?>
    let solPubkey: Driver<String?>
    
    init(
        transactionViewModel: BEListViewModelType,
        graphViewModel: WalletGraphViewModel,
        analyticsManager: AnalyticsManagerType,
        scanQrCodeAction: CocoaAction,
        wallet: Driver<Wallet?>,
        solPubkey: Driver<String?>
    ) {
        self.analyticsManager = analyticsManager
        self.graphViewModel = graphViewModel
        self.scanQrCodeAction = scanQrCodeAction
        self.wallet = wallet
        self.solPubkey = solPubkey
        
        super.init(
            header: .init(
                viewType: HeaderView.self,
                heightDimension: .estimated(557)
            ),
            viewModel: transactionViewModel,
            mapDataToSections: { viewModel in
                let transactions = viewModel.getData(type: SolanaSDK.ParsedTransaction.self)
                var dict = [[SolanaSDK.ParsedTransaction]]()
                for transaction in transactions {
                    dict.append([transaction])
                }
                
                return dict.enumerated().map { key, value in
                    SectionInfo(
                        userInfo: key,
                        layout: DefaultSection(index: key),
                        items: value
                    )
                }
            },
            layout: .init(
                header: .init(
                    viewClass: SectionHeaderView.self,
                    heightDimension: .estimated(15)
                ),
                cellType: TransactionCell.self,
                emptyCellType: WLEmptyCell.self,
                interGroupSpacing: 1,
                itemHeight: .estimated(85)
            )
        )
    }
    
    override func configureHeaderView(kind: String, indexPath: IndexPath) -> UICollectionReusableView? {
        let headerView = super.configureHeaderView(kind: kind, indexPath: indexPath) as? HeaderView
        headerView?.setUp(
            graphViewModel: graphViewModel,
            analyticsManager: analyticsManager,
            scanQrCodeAction: scanQrCodeAction,
            wallet: wallet,
            solPubkey: solPubkey
        )
        return headerView
    }
    
    override func refresh() {
        super.refresh()
        graphViewModel.reload()
    }
    
    override func dataDidLoad() {
        super.dataDidLoad()
        for (index, section) in sections.enumerated() {
            let headerView = sectionHeaderView(sectionIndex: index) as? SectionHeaderView
            headerView?.dateLabel.text = "\(section.userInfo)"
        }
    }
}
