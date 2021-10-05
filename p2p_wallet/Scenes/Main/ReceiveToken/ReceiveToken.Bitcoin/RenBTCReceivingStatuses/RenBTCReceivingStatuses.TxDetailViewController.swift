//
//  RenBTCReceivingStatuses.TxDetailViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/10/2021.
//

import Foundation
import BECollectionView
import RxSwift
import RxCocoa

extension RenBTCReceivingStatuses {
    class TxDetailViewController: WLIndicatorModalFlexibleHeightVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        private var viewModel: TxDetailViewModel
        
        // MARK: - Properties
        private lazy var collectionView: BEStaticSectionsCollectionView = .init(
            sections: [
                .init(
                    index: 0,
                    layout: .init(cellType: RecordCell.self),
                    viewModel: viewModel
                )
            ]
        )
        
        // MARK: - Initializer
        init(viewModel: TxDetailViewModel) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            title = L10n.receivingStatus
            
            stackView.addArrangedSubview(collectionView)
        }
        
        override func bind() {
            super.bind()
            viewModel.processingTxsDriver
                .drive(onNext: {[weak self] txs in
                    self?.title = L10n.receivingRenBTC(txs.first(where: {$0.tx.txid == self?.viewModel.txid})?.value.toString(maximumFractionDigits: 9) ?? "") 
                    self?.updatePresentationLayout(animated: true)
                })
                .disposed(by: disposeBag)
        }
        
        override func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
            super.calculateFittingHeightForPresentedView(targetWidth: targetWidth) +
                CGFloat(viewModel.data.count) * 72
        }
    }
    
    class TxDetailViewModel: BEListViewModelType {
        // MARK: - Dependencies
        let processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]>
        let txid: String
        
        // MARK: - Properties
        let disposeBag = DisposeBag()
        var data = [Record]()
        
        // MARK: - Initializer
        init(processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]>, txid: String) {
            self.processingTxsDriver = processingTxsDriver
            self.txid = txid
            bind()
        }
        
        func bind() {
            processingTxsDriver
                .drive(onNext: { [weak self] in
                    let new = Array($0.reversed())
                    // transform processingTxs to records
                    let processingTxs = new
                    var records = [Record]()
                    
                    guard let tx = processingTxs.first(where: {$0.tx.txid == self?.txid}) else {return}
                    if let mintedAt = tx.mintedAt {
                        records.append(.init(txid: tx.tx.txid, status: .minted, time: mintedAt, amount: tx.tx.value))
                    }
                    
                    if let submittedAt = tx.submittedAt {
                        records.append(.init(txid: tx.tx.txid, status: .submitted, time: submittedAt))
                    }
                    
                    if let confirmedAt = tx.confirmedAt {
                        records.append(.init(txid: tx.tx.txid, status: .confirmed, time: confirmedAt))
                    }
                    
                    if let threeVoteAt = tx.threeVoteAt {
                        records.append(.init(txid: tx.tx.txid, status: .waitingForConfirmation, time: threeVoteAt, vout: 3))
                    }
                    
                    if let twoVoteAt = tx.twoVoteAt {
                        records.append(.init(txid: tx.tx.txid, status: .waitingForConfirmation, time: twoVoteAt, vout: 2))
                    }
                    
                    if let oneVoteAt = tx.oneVoteAt {
                        records.append(.init(txid: tx.tx.txid, status: .waitingForConfirmation, time: oneVoteAt, vout: 1))
                    }
                    
                    if let receiveAt = tx.receivedAt {
                        records.append(.init(txid: tx.tx.txid, status: .waitingForConfirmation, time: receiveAt, vout: 0))
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
            processingTxsDriver.map {_ in ()}.asObservable()
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
        
        func setState(_ state: BEFetcherState, withData data: [AnyHashable]?) {
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
