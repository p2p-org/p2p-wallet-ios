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
            title = L10n.statusesReceived(0)
        }

        override func build() -> UIView {
            BESafeArea {
                UIStackView(axis: .vertical, alignment: .fill) {
                    NBENewDynamicSectionsCollectionView(
                        viewModel: viewModel,
                        mapDataToSections: { viewModel in
                            let data = viewModel.getData(type: LockAndMint.ProcessingTx.self)
                                
                            let dictionary = Dictionary(grouping: data, by: { Calendar.current.startOfDay(for: $0.timestamp.firstReceivedAt ?? Date()) })
                            var sectionInfo = [BEDynamicSectionsCollectionView.SectionInfo]()
                            for key in dictionary.keys.sorted(by: >) {
                                sectionInfo.append(.init(
                                    userInfo: key,
                                    items: dictionary[key]!.sorted { tx1, tx2 in
                                        guard let fra1 = tx1.timestamp.firstReceivedAt,
                                              let fra2 = tx2.timestamp.firstReceivedAt
                                        else {return true}
                                        return fra1 > fra2
                                    } as [AnyHashable]
                                ))
                            }
                            return sectionInfo
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
        
        override func bind() {
            super.bind()
            viewModel.receiveBitcoinViewModel.processingTransactionsPublisher
                .map { txs in L10n.statusesReceived(txs.count) }
                .assign(to: \.title, on: self)
                .store(in: &subscriptions)
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
