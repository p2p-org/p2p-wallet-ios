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
                
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .none
                dateFormatter.locale = Locale.shared
                
                let dictionary = Dictionary(grouping: transactions) { item -> Int in
                    guard let date = item.blockTime else {return .max}
                    let createdDate = calendar.startOfDay(for: date)
                    return calendar.dateComponents([.day], from: createdDate, to: today).day ?? 0
                }
                
                return dictionary.keys.sorted()
                    .map {key -> SectionInfo in
                        var sectionInfo: String
                        switch key {
                        case 0:
                            sectionInfo = L10n.today + ", " + dateFormatter.string(from: today)
                        case 1:
                            sectionInfo = L10n.yesterday
                            if let date = calendar.date(byAdding: .day, value: -1, to: today) {
                                sectionInfo += ", " + dateFormatter.string(from: date)
                            }
                        case .max:
                            sectionInfo = L10n.unknownDate
                        default:
                            if let date = calendar.date(byAdding: .day, value: -key, to: today) {
                                sectionInfo = dateFormatter.string(from: date)
                            } else {
                                sectionInfo = L10n.unknownDate
                            }
                        }
                        return SectionInfo(
                            userInfo: sectionInfo,
                            layout: DefaultSection(index: 0),
                            items: dictionary[key] ?? []
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
        
        contentInset.modify(dBottom: 120)
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
    
    override func configureSectionHeaderView(view: UICollectionReusableView?, sectionIndex: Int) {
        let view = view as? SectionHeaderView
        let text = sections[safe: sectionIndex]?.userInfo as? String
        view?.setUp(header: text?.uppercaseFirst)
    }
    
    override func refresh() {
        super.refresh()
        graphViewModel.reload()
    }
}
