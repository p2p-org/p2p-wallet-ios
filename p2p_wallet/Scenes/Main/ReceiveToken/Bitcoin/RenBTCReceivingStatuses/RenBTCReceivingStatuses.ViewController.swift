//
//  RenBTCReceivingStatuses.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import AnalyticsManager
import BECollectionView_Combine
import Foundation
import RenVMSwift
import Resolver
import Combine
import UIKit

extension RenBTCReceivingStatuses {
    class ViewController: BaseViewController {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }

        // MARK: - Dependencies

        @Injected private var analyticsManager: AnalyticsManager

        private var viewModel: ViewModel
        private var subscriptions = Set<AnyCancellable>()

        init(viewModel: ViewModel) {
            self.viewModel = viewModel
            super.init()

            viewModel.navigationPublisher
                .sink { [weak self] in self?.navigate(to: $0) }
                .store(in: &subscriptions)
        }

        override func build() -> UIView {
            BESafeArea {
                UIStackView(axis: .vertical, alignment: .fill) {
                    NBENewDynamicSectionsCollectionView(
                        viewModel: viewModel,
                        mapDataToSections: { viewModel in
                            CollectionViewMappingStrategy.byData(
                                viewModel: viewModel,
                                forType: LockAndMint.ProcessingTx.Timestamp.self,
                                where: \.firstReceivedAt
                            )
                        },
                        layout: .init(
                            header: .init(
                                viewClass: SectionHeaderView.self,
                                heightDimension: .estimated(15)
                            ),
                            cellType: TxCell.self,
                            emptyCellType: WLEmptyCell.self,
                            interGroupSpacing: 1,
                            itemHeight: .estimated(85)
                        ),
                        headerBuilder: { view, section in
                            guard let view = view as? SectionHeaderView else { return }
                            guard let section = section else {
                                view.setUp(headerTitle: "")
                                return
                            }

                            let date = section.userInfo as? Date ?? Date()
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateStyle = .medium
                            dateFormatter.timeStyle = .none
                            dateFormatter.locale = Locale.shared

                            view.setUp(
                                headerTitle: dateFormatter.string(from: date),
                                headerFont: UIFont.systemFont(ofSize: 12),
                                textColor: .secondaryLabel
                            )
                        }
                    ).withDelegate(self)
                }
            }
        }
    }
}

extension RenBTCReceivingStatuses.ViewController: BECollectionViewDelegate {
    func beCollectionView(collectionView _: BECollectionViewBase, didSelect item: AnyHashable) {
        guard let tx = item as? LockAndMint.ProcessingTx else { return }
        viewModel.showDetail(txid: tx.tx.txid)
    }

    private func navigate(to scene: RenBTCReceivingStatuses.NavigatableScene?) {
        switch scene {
        case let .detail(txid):
            let vc = RenBTCReceivingStatuses
                .TxDetailViewController(viewModel: .init(processingTxsPublisher: viewModel.receiveBitcoinViewModel.processingTransactionsPublisher,
                                                         txid: txid))
            show(vc, sender: nil)
        case .none:
            break
        }
    }
}
