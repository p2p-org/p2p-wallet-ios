//
// Created by Giang Long Tran on 12.04.2022.
//

import BECollectionView_Combine
import BEPureLayout
import Combine
import Foundation
import Resolver
import SolanaSwift
import TransactionParser
import UIKit

extension History {
    @MainActor
    final class Scene: BaseViewController {
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var pricesService: PricesServiceType

        let viewModel: SceneModel
        private var subscriptions = [AnyCancellable]()

        init(account: String?, symbol: String?, isEmbeded: Bool = true) {
            if let account = account, let symbol = symbol {
                viewModel = SceneModel(accountSymbol: (account, symbol))
                isEmbedded = isEmbeded
            } else {
                viewModel = SceneModel()
            }

            super.init()

            if account == nil || symbol == nil {
                navigationItem.title = L10n.history
            }

            // Start loading when wallets are ready.
            Resolver.resolve(WalletsRepository.self)
                .dataPublisher
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .first()
                .sink(receiveCompletion: { _ in

                }, receiveValue: { [weak self] _ in
                    self?.viewModel.reload()
                })
                .store(in: &subscriptions)
        }

        override func build() -> UIView {
            BEBuilder(publisher: viewModel.statePublisher) { [weak self] state in
                guard let self = self else { return UIView() }
                switch state {
                case .items:
                    return self.content
                case .empty:
                    return EmptyTransactionsView().setup {
                        $0.refreshClicked
                            .sink { [weak self] in
                                self?.viewModel.refreshPage.send()
                            }
                            .store(in: &self.subscriptions)
                    }
                case .error:
                    return ErrorView().setup {
                        $0.tryAgainClicked
                            .sink { [weak self] in
                                self?.viewModel.tryAgain.send()
                            }
                            .store(in: &self.subscriptions)
                    }
                }
            }
        }

        private var content: UIView {
            NBENewDynamicSectionsCollectionView(
                viewModel: viewModel,
                mapDataToSections: { viewModel in
                    CollectionViewMappingStrategy.byData(
                        viewModel: viewModel,
                        forType: ParsedTransaction.self,
                        where: \ParsedTransaction.blockTime
                    ).reversed()
                },
                layout: .init(
                    header: .init(
                        viewClass: SectionHeaderView.self,
                        heightDimension: .estimated(0)
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
        guard let item = item as? ParsedTransaction else { return }
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
