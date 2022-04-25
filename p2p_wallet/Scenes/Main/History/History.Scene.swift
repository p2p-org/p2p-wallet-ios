//
// Created by Giang Long Tran on 12.04.2022.
//

import BECollectionView
import BEPureLayout
import Foundation
import Resolver
import UIKit

extension History {
    final class Scene: BEScene {
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var pricesService: PricesServiceType

        let viewModel = SceneModel()

        override init() {
            super.init()

            navigationItem.title = L10n.history
            // Start loading when wallets are ready.
            Resolver.resolve(WalletsRepository.self)
                .dataObservable
                .compactMap { $0 }
                .filter { $0?.count ?? 0 > 0 }
                .first()
                .subscribe(onSuccess: { [weak self] _ in self?.viewModel.reload() })
                .disposed(by: disposeBag)
        }

        override func build() -> UIView {
            BEBuilder(driver: viewModel.showItems) { [weak self] show in
                guard let self = self else { return UIView() }
                return show ? self.content : EmptyTransactionsView()
            }
        }

        private var content: UIView {
            NBENewDynamicSectionsCollectionView(
                viewModel: viewModel,
                mapDataToSections: { viewModel in
                    CollectionViewMappingStrategy.byData(
                        viewModel: viewModel,
                        forType: SolanaSDK.ParsedTransaction.self,
                        where: \SolanaSDK.ParsedTransaction.blockTime
                    ).reversed()
                },
                layout: .init(
                    header: .init(
                        viewClass: SectionHeaderView.self,
                        heightDimension: .estimated(15)
                    ),
                    cellType: Cell.self,
                    emptyCellType: WLEmptyCell.self,
                    numberOfLoadingCells: 7,
                    interGroupSpacing: 1,
                    itemHeight: .estimated(64)
                ),
                headerBuilder: { view, sectionInfo in
                    guard let view = view as? SectionHeaderView else { return }

                    if let date = sectionInfo?.userInfo as? String {
                        view.setUp(headerTitle: date)
                    } else {
                        // We have to have this text, otherwise the header cell will jump,
                        // because passing empty string will resize cell height
                        view.setUp(headerTitle: " ")
                    }
                }
            ).withDelegate(self)
        }
    }
}

// MARK: - BECollectionViewDelegate

extension History.Scene: BECollectionViewDelegate {
    func beCollectionView(collectionView _: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let item = item as? SolanaSDK.ParsedTransaction else { return }

        let viewController = History.TransactionViewController(
            viewModel: .init(
                transaction: item,
                clipboardManager: clipboardManager,
                pricesService: pricesService
            )
        )
        viewController.dismissCompletion = { [weak self] in
            self?.dismiss(animated: true)
        }
        present(viewController, interactiveDismissalType: .none)
    }
}
