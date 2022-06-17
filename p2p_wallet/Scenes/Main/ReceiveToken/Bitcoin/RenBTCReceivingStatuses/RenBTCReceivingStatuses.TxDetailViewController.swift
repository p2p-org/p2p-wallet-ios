//
//  RenBTCReceivingStatuses.TxDetailViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import BECollectionView
import Foundation
import RenVMSwift
import RxCocoa
import RxSwift

extension RenBTCReceivingStatuses {
    class TxDetailViewController: BaseViewController {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }

        private var viewModel: TxDetailViewModel

        init(viewModel: TxDetailViewModel) {
            self.viewModel = viewModel
            super.init()
        }

        override func build() -> UIView {
            BESafeArea {
                UIStackView(axis: .vertical, alignment: .fill) {
                    NewWLNavigationBar(initialTitle: L10n.receivingStatus, separatorEnable: false)
                        .onBack { [unowned self] in self.back() }
                        .setup { view in
                            viewModel.currentTx
                                .map { tx in
                                    guard let value = tx?.value else { return L10n.receivingStatus }
                                    return L10n.receivingRenBTC(value.toString(maximumFractionDigits: 10))
                                }
                                .drive(view.titleLabel.rx.text)
                                .disposed(by: disposeBag)
                        }
                    NBENewDynamicSectionsCollectionView(
                        viewModel: viewModel,
                        mapDataToSections: { viewModel in
                            CollectionViewMappingStrategy.byData(
                                viewModel: viewModel,
                                forType: Record.self,
                                where: \Record.time
                            )
                        },
                        layout: .init(
                            header: .init(
                                viewClass: SectionHeaderView.self,
                                heightDimension: .estimated(15)
                            ),
                            cellType: RecordCell.self,
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
                    )
                }
            }
        }
    }

    class TxDetailViewModel: BEListViewModelType {
        // MARK: - Dependencies

        let processingTxsDriver: Driver<[LockAndMint.ProcessingTx]>
        let txid: String

        // MARK: - Properties

        let disposeBag = DisposeBag()
        var data = [Record]()

        // MARK: - Initializer

        init(processingTxsDriver: Driver<[LockAndMint.ProcessingTx]>, txid: String) {
            self.processingTxsDriver = processingTxsDriver
            self.txid = txid
            bind()
        }

        var currentTx: Driver<LockAndMint.ProcessingTx?> {
            processingTxsDriver.map { [weak self] in $0.first { tx in tx.tx.txid == self?.txid } }
        }

        func bind() {
            processingTxsDriver
                .drive(onNext: { [weak self] in
                    let new = Array($0.reversed())
                    // transform processingTxs to records
                    let processingTxs = new
                    var records = [Record]()

                    guard let tx = processingTxs.first(where: { $0.tx.txid == self?.txid }) else { return }
                    if let mintedAt = tx.mintedAt {
                        records.append(.init(txid: tx.tx.txid, status: .minted, time: mintedAt, amount: tx.tx.value))
                    }

                    if let submittedAt = tx.submitedAt {
                        records.append(.init(txid: tx.tx.txid, status: .submitted, time: submittedAt))
                    }

                    if let confirmedAt = tx.confirmedAt {
                        records.append(.init(txid: tx.tx.txid, status: .confirmed, time: confirmedAt))
                    }

                    if let threeVoteAt = tx.threeVoteAt {
                        records
                            .append(.init(txid: tx.tx.txid, status: .waitingForConfirmation, time: threeVoteAt,
                                          vout: 3))
                    }

                    if let twoVoteAt = tx.twoVoteAt {
                        records
                            .append(.init(txid: tx.tx.txid, status: .waitingForConfirmation, time: twoVoteAt, vout: 2))
                    }

                    if let oneVoteAt = tx.oneVoteAt {
                        records
                            .append(.init(txid: tx.tx.txid, status: .waitingForConfirmation, time: oneVoteAt, vout: 1))
                    }

                    if let receiveAt = tx.receivedAt {
                        records
                            .append(.init(txid: tx.tx.txid, status: .waitingForConfirmation, time: receiveAt, vout: 0))
                    }

                    records.sort { rc1, rc2 in
                        if rc1.time == rc2.time {
                            return (rc1.vout ?? 0) > (rc2.vout ?? 0)
                        } else {
                            return rc1.time > rc2.time
                        }
                    }

                    self?.data = records
                })
                .disposed(by: disposeBag)
        }

        var dataDidChange: Observable<Void> {
            processingTxsDriver.map { _ in () }.asObservable()
        }

        var currentState: BEFetcherState {
            .loaded
        }

        var isPaginationEnabled: Bool {
            false
        }

        func reload() {
            // do nothing
        }

        func convertDataToAnyHashable() -> [AnyHashable] {
            data as [AnyHashable]
        }

        func fetchNext() {
            // do nothing
        }

        func setState(_: BEFetcherState, withData _: [AnyHashable]?) {
            // do nothing
        }

        func refreshUI() {
            // do nothing
        }

        func getCurrentPage() -> Int? {
            0
        }
    }
}
