//
//  RenBTCReceivingStatuses.TxDetailViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import BECollectionView_Combine
import Foundation
import RenVMSwift
import Combine

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
                    NBENewDynamicSectionsCollectionView(
                        viewModel: viewModel,
                        mapDataToSections: { viewModel in
                            CollectionViewMappingStrategy.byData(
                                viewModel: viewModel,
                                forType: Record.self,
                                where: \.time
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

    class TxDetailViewModel: BECollectionViewModelType {
        // MARK: - Dependencies

        let processingTxsPublisher: AnyPublisher<[LockAndMint.ProcessingTx], Never>
        let txid: String

        // MARK: - Properties

        var subscriptions = [AnyCancellable]()
        var data = [Record]()

        // MARK: - Initializer

        init(processingTxsPublisher: AnyPublisher<[LockAndMint.ProcessingTx], Never>, txid: String) {
            self.processingTxsPublisher = processingTxsPublisher
            self.txid = txid
            bind()
        }

        var currentTxPublisher: AnyPublisher<LockAndMint.ProcessingTx?, Never> {
            processingTxsPublisher.map { [weak self] in $0.first { tx in tx.tx.txid == self?.txid } }
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }

        func bind() {
            processingTxsPublisher
                .receive(on: RunLoop.main)
                .sink { [weak self] in
                    guard let tx = $0.first(where: { $0.tx.txid == self?.txid }) else { return }
                    let records = self?.mapTxToRecords(tx)
                    self?.data = records ?? []
                }
                .store(in: &subscriptions)
        }
        
        private func mapTxToRecords(_ tx: LockAndMint.ProcessingTx) -> [Record] {
            var voteAt = [UInt: Date]()
            var confirmedAt: Date?
            var submitedAt: Date?
            var mintedAt: Date?
            var errorAt: Date?
            var error: LockAndMint.ProcessingError?
            
            switch tx.state {
            case .confirming:
                voteAt = tx.timestamp.voteAt
            case .confirmed:
                voteAt = fillEmptyVoteAt(tx.timestamp.voteAt)
                confirmedAt = tx.timestamp.confirmedAt ?? Date()
            case .submited:
                voteAt = fillEmptyVoteAt(tx.timestamp.voteAt)
                confirmedAt = tx.timestamp.confirmedAt ?? Date()
                submitedAt = tx.timestamp.submitedAt ?? Date()
            case .minted:
                voteAt = fillEmptyVoteAt(tx.timestamp.voteAt)
                confirmedAt = tx.timestamp.confirmedAt ?? Date()
                submitedAt = tx.timestamp.submitedAt ?? Date()
                mintedAt = tx.timestamp.mintedAt ?? Date()
            case let .ignored(err):
                voteAt = fillEmptyVoteAt(tx.timestamp.voteAt)
                confirmedAt = tx.timestamp.confirmedAt ?? Date()
                submitedAt = tx.timestamp.submitedAt ?? Date()
                errorAt = tx.timestamp.ignoredAt ?? Date()
                error = err
            }
            
            var records = [Record]()
            for key in voteAt.keys.sorted(by: <) {
                records
                    .append(.init(txid: tx.tx.txid, status: .waitingForConfirmation, time: voteAt[key]!, vout: key))
            }
            if let confirmedAt = confirmedAt {
                records.append(.init(txid: tx.tx.txid, status: .confirmed, time: confirmedAt))
            }
            if let submittedAt = submitedAt {
                records.append(.init(txid: tx.tx.txid, status: .submitted, time: submittedAt))
            }
            if let mintedAt = mintedAt {
                records.append(.init(txid: tx.tx.txid, status: .minted, time: mintedAt, amount: tx.tx.value))
            }
            if let errorAt = errorAt {
                records.append(.init(txid: tx.tx.txid, status: .error(error ?? .other("Unknown error")), time: errorAt, amount: tx.tx.value))
            }
            return records.reversed()
        }
        
        private func fillEmptyVoteAt(_ voteAt: [UInt: Date]) -> [UInt: Date] {
            var voteAt = voteAt
            if voteAt.keys.count < LockAndMint.ProcessingTx.maxVote {
                // fill votes
                let count = UInt(voteAt.keys.count)
                for i in count..<LockAndMint.ProcessingTx.maxVote {
                    voteAt[i] = Date()
                }
            }
            return voteAt
        }
        
        var dataDidChange: AnyPublisher<Void, Never> {
            processingTxsPublisher.map { _ in () }
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        var state: BECollectionView_Core.BEFetcherState {
            .loaded
        }
        
        let isPaginationEnabled: Bool = false
        
        func reload() {
            // do nothing
        }
        
        func convertDataToAnyHashable() -> [AnyHashable] {
            data as [AnyHashable]
        }
        
        func fetchNext() {
            // do nothing
        }
    }
}
