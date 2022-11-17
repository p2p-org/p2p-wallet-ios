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
        private var viewModel: TxDetailViewModel
        private var subscriptions = Set<AnyCancellable>()

        init(viewModel: TxDetailViewModel) {
            self.viewModel = viewModel
            super.init()
            title = L10n.receivingRenBTC(0)
        }

        override func build() -> UIView {
            BESafeArea {
                UIStackView(axis: .vertical, alignment: .fill) {
                    NBENewDynamicSectionsCollectionView(
                        viewModel: viewModel,
                        mapDataToSections: { viewModel in
                            let data = viewModel.getData(type: Record.self)
                            let dictionary = Dictionary(grouping: data, by: { Calendar.current.startOfDay(for: $0.time) })
                            var sectionInfo = [BEDynamicSectionsCollectionView.SectionInfo]()
                            for key in dictionary.keys.sorted(by: >) {
                                sectionInfo.append(.init(userInfo: key, items: dictionary[key]!.sorted { $0.time > $1.time } as [AnyHashable]))
                            }
                            return sectionInfo
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
        
        override func bind() {
            super.bind()
            viewModel.currentTxPublisher
                .map { tx in
                    guard let value = tx?.value else { return L10n.receivingStatus }
                    return L10n.receivingRenBTC(value.toString(maximumFractionDigits: 10))
                }
                .assign(to: \.title, on: self)
                .store(in: &subscriptions)
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
            processingTxsPublisher.map { [weak self] in $0.first { tx in tx.tx.id == self?.txid } }
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }

        func bind() {
            processingTxsPublisher
                .receive(on: RunLoop.main)
                .sink { [weak self] in
                    guard let tx = $0.first(where: { $0.tx.id == self?.txid }) else { return }
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
                voteAt = fillEmptyVoteAt(tx.timestamp)
                confirmedAt = tx.timestamp.confirmedAt ?? Date()
            case .submited:
                voteAt = fillEmptyVoteAt(tx.timestamp)
                confirmedAt = tx.timestamp.confirmedAt ?? Date()
                submitedAt = tx.timestamp.submitedAt ?? Date()
            case .minted:
                voteAt = fillEmptyVoteAt(tx.timestamp)
                confirmedAt = tx.timestamp.confirmedAt ?? Date()
                submitedAt = tx.timestamp.submitedAt ?? Date()
                mintedAt = tx.timestamp.mintedAt ?? Date()
            case let .ignored(err):
                voteAt = fillEmptyVoteAt(tx.timestamp)
                confirmedAt = tx.timestamp.confirmedAt ?? Date()
                submitedAt = tx.timestamp.submitedAt ?? Date()
                errorAt = tx.timestamp.ignoredAt ?? Date()
                error = err
            }
            
            var records = [Record]()
            for key in voteAt.keys.sorted(by: <) {
                records
                    .append(.init(txid: tx.tx.id, status: .waitingForConfirmation, time: voteAt[key]!, vout: key))
            }
            if let confirmedAt = confirmedAt {
                records.append(.init(txid: tx.tx.id, status: .confirmed, time: confirmedAt))
            }
            if let submittedAt = submitedAt {
                records.append(.init(txid: tx.tx.id, status: .submitted, time: submittedAt))
            }
            if let mintedAt = mintedAt {
                records.append(.init(txid: tx.tx.id, status: .minted, time: mintedAt, amount: tx.tx.value))
            }
            if let errorAt = errorAt {
                records.append(.init(txid: tx.tx.id, status: .error(error ?? .other("Unknown error")), time: errorAt, amount: tx.tx.value))
            }
            return records.reversed()
        }
        
        private func fillEmptyVoteAt(_ timestamp: LockAndMint.ProcessingTx.Timestamp) -> [UInt: Date] {
            var voteAt = timestamp.voteAt
            if voteAt.keys.count < BTCExplorerAPIClient.maxConfirmations {
                // fill votes
                let count = UInt(voteAt.keys.count)
                for i in count...BTCExplorerAPIClient.maxConfirmations {
                    voteAt[i] = timestamp.lastVoteAt
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
