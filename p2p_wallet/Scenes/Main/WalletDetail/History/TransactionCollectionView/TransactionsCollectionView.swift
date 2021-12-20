//
//  TransactionsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation
import BECollectionView
import Action
import RxSwift
import RxCocoa

class TransactionsCollectionView: BEDynamicSectionsCollectionView {
    let graphViewModel: WalletGraphViewModel
    @Injected private var analyticsManager: AnalyticsManagerType
    let wallet: Driver<Wallet?>
    let nativePubkey: Driver<String?>
    let disposeBag = DisposeBag()
    
    init(
        transactionViewModel: TransactionsViewModel,
        graphViewModel: WalletGraphViewModel,
        wallet: Driver<Wallet?>,
        nativePubkey: Driver<String?>
    ) {
        self.graphViewModel = graphViewModel
        self.wallet = wallet
        self.nativePubkey = nativePubkey
        
        super.init(
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
    
//    override func bind() {
//        super.bind()
//        (viewModel as! TransactionsViewModel).isFetchingReceiptDriver
//            .drive(onNext: {isFetching in
//                if isFetching {
//                    UIApplication.shared.showToast(
//                        message: "✅ " +  L10n.ReceivedNewTokens.downloadingReceipt
//                    )
//                }
//            })
//            .disposed(by: disposeBag)
//    }
    
    override func configureSectionHeaderView(view: UICollectionReusableView?, sectionIndex: Int) {
        let view = view as? SectionHeaderView
        let text = sections[safe: sectionIndex]?.userInfo as? String
        view?.setUp(header: text?.uppercaseFirst)
    }
    
    override func configureCell(indexPath: IndexPath, item: BECollectionViewItem) -> UICollectionViewCell? {
        let cell = super.configureCell(indexPath: indexPath, item: item)
        if let cell = cell as? WLEmptyCell {
            cell.titleLabel.text = L10n.noTransactionsYet
            cell.subtitleLabel.text = L10n.youHaveNotMadeAnyTransactionYet
            cell.imageView.image = .transactionEmpty
        }
        return cell
    }
    
    override func refresh() {
        super.refresh()
        graphViewModel.reload()
    }
}
