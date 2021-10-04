//
//  ReceiveToken.ReceivingRenBTCStatusViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/10/2021.
//

import Foundation
import RxSwift
import RxCocoa
import BECollectionView

extension ReceiveToken {
    class ReceivingRenBTCStatusViewController: WLIndicatorModalFlexibleHeightVC {
        // MARK: - Dependencies
        private let viewModel: ViewModel
        
        private lazy var collectionView: BEStaticSectionsCollectionView = .init(
            sections: [
                .init(
                    index: 0,
                    layout: .init(cellType: Cell.self),
                    viewModel: viewModel
                )
            ]
        )
        
        init(receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType) {
            self.viewModel = ViewModel(receiveBitcoinViewModel: receiveBitcoinViewModel)
            super.init()
        }
        
        override func setUp() {
            super.setUp()
            title = L10n.receivingStatus
            
            stackView.addArrangedSubview(collectionView)
        }
        
        override func calculateFittingHeightForPresentedView(targetWidth: CGFloat) -> CGFloat {
            .infinity
        }
    }
}

private extension ReceiveToken.ReceivingRenBTCStatusViewController {
    struct Record: Hashable {
        enum Status: String, Equatable {
            case waitingForConfirmation, confirmed, submitted, minted
        }
        
        let tx: RenVM.LockAndMint.TxDetail
        let status: Status
        let time: Date
        
        var stringValue: String {
            switch status {
            case .waitingForConfirmation:
                return L10n.waitingForDepositConfirmation
            case .confirmed:
                return L10n.submittingToRenVM
            case .submitted:
                return L10n.minting
            case .minted:
                return L10n.successfullyMintedRenBTC(
                    tx.value.convertToBalance(decimals: 8)
                        .toString(maximumFractionDigits: 9)
                )
            }
        }
    }
    
    class ViewModel: BEListViewModel<Record> {
        private let disposeBag = DisposeBag()
        var records = [Record]()
        init(receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType) {
            super.init(initialData: [])
            
            receiveBitcoinViewModel.processingTxsDriver
                .drive(onNext: { [weak self] in
                    let new = Array($0.reversed())
                    // transform processingTxs to records
                    let processingTxs = new
                    var records = [Record]()
                    for tx in processingTxs {
                        if let mintedAt = tx.mintedAt {
                            records.append(.init(tx: tx.tx, status: .minted, time: mintedAt))
                        }
                        
                        if let submittedAt = tx.submittedAt {
                            records.append(.init(tx: tx.tx, status: .submitted, time: submittedAt))
                        }
                        
                        if let confirmedAt = tx.confirmedAt {
                            records.append(.init(tx: tx.tx, status: .confirmed, time: confirmedAt))
                        }
                        
                        if let receivedAt = tx.receivedAt {
                            records.append(.init(tx: tx.tx, status: .waitingForConfirmation, time: receivedAt))
                        }
                    }
                    
                    records.sort { rc1, rc2 in
                        rc1.time > rc2.time
                    }
                    
                    self?.records = records
                    self?.overrideData(by: records)
                })
                .disposed(by: disposeBag)
        }
        
        override func createRequest() -> Single<[Record]> {
            .just(records)
        }
    }
    
    class Cell: BaseCollectionViewCell, BECollectionViewCell {
        override var padding: UIEdgeInsets {.init(x: 20, y: 12)}
        
        // MARK: - Subviews
        private lazy var statusLabel = UILabel(textSize: 15, weight: .medium, numberOfLines: 0)
        private lazy var timestampLabel = UILabel(textSize: 13, weight: .medium, textColor: .textSecondary)
        private lazy var resultLabel = UILabel(textSize: 15, weight: .semibold)
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            stackView.spacing = 8
            stackView.axis = .horizontal
            stackView.alignment = .center
            
            stackView.addArrangedSubviews {
                UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
                    statusLabel
                    timestampLabel
                }
                resultLabel.withContentHuggingPriority(.required, for: .horizontal)
            }
        }
        
        func setUp(with item: AnyHashable?) {
            guard let tx = item as? Record else {return}
            statusLabel.text = tx.stringValue
            resultLabel.isHidden = true
            timestampLabel.text = tx.time.string(withFormat: "MMMM dd, YYYY HH:mm a")
            switch tx.status {
            case .waitingForConfirmation:
                resultLabel.isHidden = false
                let vout = tx.tx.vout
                let max = 3
                resultLabel.text = "\(tx.tx.vout)/3"
                if vout == 0 {
                    resultLabel.textColor = .alert
                } else if vout == max {
                    resultLabel.textColor = .textGreen
                } else {
                    resultLabel.textColor = .textBlack
                }
            case .minted:
                resultLabel.isHidden = false
                resultLabel.text = "+ \(tx.tx.value.convertToBalance(decimals: 8).toString(maximumFractionDigits: 9)) renBTC"
                resultLabel.textColor = .textGreen
            default:
                break
            }
        }
    }
}
