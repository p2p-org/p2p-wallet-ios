//
//  PT.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import Foundation
import UIKit
import BEPureLayout

extension ProcessTransaction {
    class ViewController: WLModalViewController {
        // MARK: - Dependencies
        private let viewModel: ProcessTransactionViewModelType
        
        // MARK: - Properties
        var makeAnotherTransactionHandler: (() -> Void)?
        
        // MARK: - Initializer
        init(viewModel: ProcessTransactionViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            viewModel.sendAndObserveTransaction()
        }
        
        override func build() -> UIView {
            BEContainer {
                BEVStack(spacing: 4) {
                    // The transaction is being processed
                    UILabel(
                        text: nil,
                        textSize: 20,
                        weight: .semibold,
                        numberOfLines: 0,
                        textAlignment: .center
                    )
                        .setup {label in
                            viewModel.pendingTransactionDriver
                                .map { info -> String in
                                    let originalText = info.rawTransaction.isSwap ? L10n.theSwapIsBeingProcessed: L10n.theTransactionIsBeingProcessed
                                    
                                    switch info.status {
                                    case .sending, .confirmed:
                                        return originalText
                                    case .error:
                                        return L10n.theTransactionHasBeenRejected
                                    case .finalized:
                                        switch info.rawTransaction {
                                        case let transaction as SendTransaction:
                                            return L10n.wasSentSuccessfully(transaction.sender.token.symbol)
                                        case let transaction as OrcaSwapTransaction:
                                            return L10n.swappedSuccessfully(transaction.sourceWallet.token.symbol, transaction.destinationWallet.token.symbol)
                                        default:
                                            fatalError()
                                        }
                                    }
                                }
                                .drive(label.rx.text)
                                .disposed(by: disposeBag)
                        }
                        .padding(.init(x: 18, y: 0))
                    
                    // Detail
                    UILabel(
                        text: "0.00227631 renBTC → DkmT...JnBw",
                        textSize: 15,
                        textColor: .textSecondary,
                        numberOfLines: 0,
                        textAlignment: .center
                    )
                        .setup { label in
                            label.text = viewModel.getMainDescription()
                        }
                        .padding(.init(all: 18, excludingEdge: .top))
                    
                    // Loader
                    BEZStack {
                        // Process indicator
                        BEZStackPosition {
                            ProgressView()
                                .setup {progressView in
                                    viewModel.pendingTransactionDriver
                                        .map {$0.status}
                                        .drive(progressView.rx.transactionStatus)
                                        .disposed(by: disposeBag)
                                }
                                .centered(.vertical)
                        }
                        
                        // Icon
                        BEZStackPosition {
                            UIImageView(width: 44, height: 44)
                                .setup { imageView in
                                    viewModel.pendingTransactionDriver
                                        .map {$0.status}
                                        .map {status -> UIImage in
                                            switch status {
                                            case .sending, .confirmed:
                                                return .squircleTransactionProcessing
                                            case .finalized:
                                                return .squircleTransactionCompleted
                                            case .error:
                                                return .squircleTransactionError
                                            }
                                        }
                                        .drive(imageView.rx.image)
                                        .disposed(by: disposeBag)
                                }
                                .centered(.horizontal)
                        }
                    }
                        .padding(.init(only: .bottom, inset: 18))
                    
                    // Transaction ID
                    BEHStack(spacing: 4, alignment: .top, distribution: .fill) {
                        UILabel(text: L10n.transactionID, textSize: 15, textColor: .textSecondary)
                        
                        BEVStack(spacing: 4, alignment: .fill, distribution: .fill) {
                            BEHStack(spacing: 4, alignment: .center, distribution: .fill) {
                                UILabel(
                                    text: "4gj7UK2mG...NjweNS39N",
                                    textSize: 15,
                                    textAlignment: .right
                                )
                                    .setup { label in
                                        viewModel.pendingTransactionDriver
                                            .map {$0.transactionId?.truncatingMiddle(numOfSymbolsRevealed: 9, numOfSymbolsRevealedInSuffix: 9)}
                                            .drive(label.rx.text)
                                            .disposed(by: disposeBag)
                                    }
                                UIImageView(width: 16, height: 16, image: .transactionShowInExplorer, tintColor: .textSecondary)
                            }
                            UILabel(text: L10n.tapToViewInExplorer, textSize: 15, textColor: .textSecondary, numberOfLines: 0, textAlignment: .right)
                        }
                            .onTap { [weak self] in
                                self?.navigate(to: .explorer)
                            }
                    }
                        .padding(.init(top: 0, left: 18, bottom: 36, right: 18))
                        .setup { view in
                            viewModel.pendingTransactionDriver
                                .map {$0.transactionId == nil}
                                .drive(view.rx.isHidden)
                                .disposed(by: disposeBag)
                            
                            viewModel.pendingTransactionDriver
                                .map {$0.transactionId == nil}
                                .drive(onNext: { [weak self] _ in
                                    UIView.animate(withDuration: 0.3) {
                                        self?.updatePresentationLayout()
                                    }
                                })
                                .disposed(by: disposeBag)
                        }
                    
                    // Buttons
                    BEVStack(spacing: 10) {
                        WLStepButton.main(image: .info, text: L10n.showTransactionDetails)
                            .onTap { [weak self] in
                                self?.viewModel.navigate(to: .detail)
                            }
                        WLStepButton.sub(text: L10n.makeAnotherTransaction)
                            .setup { button in
                                viewModel.pendingTransactionDriver
                                    .map {$0.status.error == nil}
                                    .map {$0 ? L10n.makeAnotherTransaction: L10n.tryAgain}
                                    .drive(button.rx.text)
                                    .disposed(by: disposeBag)
                            }
                            .onTap { [weak self] in
                                self?.viewModel.makeAnotherTransactionOrRetry()
                            }
                    }
                        .padding(.init(x: 18, y: 0))
                }
                    .padding(.init(x: 0, y: 18))
            }
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else {return}
            switch scene {
            case .detail:
                let vm = TransactionDetail.ViewModel(observingTransactionIndex: viewModel.getObservingTransactionIndex())
                let vc = TransactionDetail.ViewController(viewModel: vm)
                vc.modalPresentationStyle = .fullScreen
                present(vc, animated: true, completion: nil)
            case .explorer:
                showWebsite(url: "https://explorer.solana.com/tx/" + (viewModel.transactionID ?? ""))
            case .makeAnotherTransaction:
                dismiss(animated: true) {
                    self.makeAnotherTransactionHandler?()
                }
            }
        }
    }
}
