//
//  PT.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import Foundation
import UIKit
import BEPureLayout

extension PT {
    class ViewController: WLModalViewController {
        // MARK: - Dependencies
        private let viewModel: PTViewModelType
        
        // MARK: - Properties
        
        init(viewModel: PTViewModelType) {
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
                        .setup { label in
                            let originalText = viewModel.isSwapping ? L10n.theSwapIsBeingProcessed: L10n.theTransactionIsBeingProcessed
                            
                            viewModel.transactionInfoDriver
                                .map {$0.status.error == nil}
                                .map {$0 ? originalText: L10n.theTransactionHasBeenRejected}
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
                            label.text = viewModel.getTransactionDescription(withAmount: true)
                        }
                        .padding(.init(all: 18, excludingEdge: .top))
                    
                    // Loader
                    BEZStack {
                        // Process indicator
                        BEZStackPosition {
                            UIProgressView(height: 2)
                                .setup {view in
                                    viewModel.transactionInfoDriver
                                        .map {$0.status.progress}
                                        .drive(view.rx.progress)
                                        .disposed(by: disposeBag)
                                    
                                    viewModel.transactionInfoDriver
                                        .map {$0.status.error == nil}
                                        .map { $0 ? UIColor.h5887ff: UIColor.alert }
                                        .drive(view.rx.progressTintColor)
                                        .disposed(by: disposeBag)
                                }
                                .centered(.vertical)
                        }
                        
                        // Icon
                        BEZStackPosition {
                            UIImageView(width: 44, height: 44, image: .squircleTransactionProcessing)
                                .setup { imageView in
                                    viewModel.transactionInfoDriver
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
                                UILabel(text: "4gj7UK2mG...NjweNS39N", textSize: 15, textAlignment: .right)
                                    .setup { label in
                                        viewModel.transactionInfoDriver
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
                            viewModel.transactionInfoDriver
                                .map {$0.transactionId == nil}
                                .drive(view.rx.isHidden)
                                .disposed(by: disposeBag)
                            
                            viewModel.transactionInfoDriver
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
                                viewModel.transactionInfoDriver
                                    .map {$0.status.error == nil}
                                    .map {$0 ? L10n.makeAnotherTransaction: L10n.retry}
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
                let vc = DetailViewController(viewModel: viewModel)
                present(vc, animated: true, completion: nil)
            case .explorer:
                showWebsite(url: "https://explorer.solana.com/tx/" + (viewModel.transactionID ?? ""))
            }
        }
    }
}
