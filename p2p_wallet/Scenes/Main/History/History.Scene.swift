//
// Created by Giang Long Tran on 12.04.2022.
//

import BECollectionView
import BEPureLayout
import Foundation
import Resolver
import SolanaSwift
import TransactionParser
import UIKit

extension History {
    final class Scene: BaseViewController {
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var pricesService: PricesServiceType

        let viewModel: SceneModel

        override init() {
            viewModel = SceneModel()
            super.init()

            navigationItem.title = L10n.history
            // Start loading when wallets are ready.
            Resolver.resolve(WalletsRepository.self)
                .dataPublisher
                .asObservable()
                .filter { $0.count > 0 }
                .first()
                .subscribe(onSuccess: { [weak self] _ in self?.viewModel.reload() })
                .disposed(by: disposeBag)
        }

        init(account: String, symbol: String, isEmbeded: Bool = true) {
            viewModel = SceneModel(accountSymbol: (account, symbol))

            super.init()
            isEmbedded = isEmbeded

            // Start loading when wallets are ready.
            Resolver.resolve(WalletsRepository.self)
                .dataPublisher
                .asObservable()
                .filter { $0.count > 0 }
                .first()
                .subscribe(onSuccess: { [weak self] _ in self?.viewModel.reload() })
                .disposed(by: disposeBag)
        }

        override func build() -> UIView {
            BEBuilder(driver: viewModel.stateDriver) { [weak self] state in
                guard let self = self else { return UIView() }
                switch state {
                case .items:
                    return self.content
                case .empty:
                    return EmptyTransactionsView().setup {
                        $0.rx.refreshClicked
                            .bind(to: self.viewModel.refreshPage)
                            .disposed(by: self.disposeBag)
                    }
                case .error:
                    return ErrorView().setup {
                        $0.rx.tryAgainClicked
                            .bind(to: self.viewModel.tryAgain)
                            .disposed(by: self.disposeBag)
                    }
                }
            }
        }

        private var content: UIView {
            NBENewDynamicSectionsCollectionView(
                viewModel: viewModel,
                mapDataToSections: { viewModel in
                    // get items
                    let items = viewModel.getData(type: HistoryItem.self)
                    
                    // put sell transactions first, then other transactions
                    var sellTransactions = [HistoryItem]()
                    var otherTransactions = [HistoryItem]()
                    
                    for item in items {
                        switch item {
                        case .sellTransaction:
                            sellTransactions.append(item)
                        case .parsedTransaction:
                            otherTransactions.append(item)
                        }
                    }
                    
                    let sellTransactionsSection: BEDynamicSectionsCollectionView.SectionInfo? = sellTransactions.isEmpty ? nil: .init(
                        userInfo: "",
                        items: sellTransactions
                    )

                    let dictionary = Dictionary(grouping: otherTransactions) { item -> Date in
                        let date = item.blockTime ?? Date()
                        return Calendar.current.startOfDay(for: date)
                    }
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .none
                    dateFormatter.locale = Locale.shared
                    
                    let otherTransactionsSections = dictionary.keys.sorted().reversed()
                        .map { key in
                            BEDynamicSectionsCollectionView.SectionInfo(
                                userInfo: dateFormatter.string(from: key),
                                items: dictionary[key] ?? []
                            )
                        }

                    var result = [BEDynamicSectionsCollectionView.SectionInfo]()
                    if let sellTransactionsSection {
                        result.append(sellTransactionsSection)
                    }
                    result += otherTransactionsSections
                    return result
                },
                layout: .init(
                    header: .init(
                        viewClass: SectionHeaderView.self,
                        heightDimension: .estimated(0)
                    ),
                    cellType: TransactionCell.self,
                    emptyCellType: WLEmptyCell.self,
                    numberOfLoadingCells: 7,
                    interGroupSpacing: 1,
                    itemHeight: .estimated(64)
                ),
                headerBuilder: { view, sectionInfo in
                    guard let view = view as? SectionHeaderView else { return }

                    if let date = sectionInfo?.userInfo as? String {
                        view.setUp(headerTitle: date)
                    }
                }
            ).withDelegate(self)
        }

        // MARK: - Navigation bar appearance

        private var isEmbedded = false

        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            isEmbedded ? .embeded : super.preferredNavigationBarStype
        }
    }
}

// MARK: - BECollectionViewDelegate

extension History.Scene: BECollectionViewDelegate {
    func beCollectionView(collectionView _: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let item = item as? HistoryItem else { return }

        switch item {
        case .parsedTransaction(let transaction):
            let viewController = History.TransactionViewController(
                viewModel: .init(
                    transaction: transaction,
                    clipboardManager: clipboardManager,
                    pricesService: pricesService
                )
            )
            viewController.dismissCompletion = { [weak self] in
                self?.dismiss(animated: true)
            }
            present(viewController, interactiveDismissalType: .none)
        case .sellTransaction(_):
            // Only history of all tokens support displaying sell transactions. 
            viewModel.onTap(item: item)
        }
    }
}
