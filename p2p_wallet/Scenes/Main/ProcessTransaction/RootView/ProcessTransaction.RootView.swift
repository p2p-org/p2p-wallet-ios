//
//  ProcessTransaction.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 02/06/2021.
//

import UIKit
import RxSwift
import RxCocoa

extension ProcessTransaction {
    class RootView: BEView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        let viewModel: ProcessTransactionViewModelType
        
        // MARK: - Subviews
        lazy var stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)
        lazy var titleLabel = UILabel(textSize: 20, weight: .semibold, numberOfLines: 0, textAlignment: .center)
        lazy var subtitleLabel = UILabel(textColor: .textSecondary, numberOfLines: 1, textAlignment: .center)
        lazy var transactionStatusImageView = UIImageView(width: 44, height: 44, image: .transactionProcessing)
        lazy var transactionIndicatorView: TransactionIndicatorView = {
            let indicatorView = TransactionIndicatorView(height: 1, backgroundColor: .separator)
            indicatorView.tintColor = .h5887ff
            return indicatorView
        }()
        lazy var transactionIDLabel = UILabel(textSize: 15, textAlignment: .right)
        
        // MARK: - Substackviews
        lazy var transactionIDStackView = UIStackView(axis: .horizontal, spacing: 0, alignment: .top, distribution: .fill) {
            UILabel(text: L10n.transactionID, textSize: 15, textColor: .textSecondary)
            BEStackViewSpacing(4)
            UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                UIStackView(axis: .horizontal, spacing: 4, alignment: .center, distribution: .fill) {
                    transactionIDLabel
                    UIImageView(width: 16, height: 16, image: .transactionShowInExplorer, tintColor: .textSecondary)
                }
                
                UILabel(text: L10n.tapToViewInExplorer, textSize: 15, textColor: .textSecondary, numberOfLines: 0, textAlignment: .right)
                    
            }
                .onTap(self, action: #selector(showExplorer))
        }
            .padding(.init(x: 20, y: 0))
        lazy var buttonStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill) {
            primaryButton
            secondaryButton
        }
        lazy var primaryButton = WLStepButton.main(image: .info, text: L10n.showTransactionDetails)
        lazy var secondaryButton = WLStepButton.sub(text: L10n.makeAnotherTransaction)
        
        // MARK: - Initializers
        init(viewModel: ProcessTransactionViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        // MARK: - Methods
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            
        }
        
        // MARK: - Layout
        private func layout() {
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 0, y: 18))
            
            stackView.spacing = 0
        }
        
        private func bind() {
            switch viewModel.transactionType {
            case .closeAccount:
                viewModel.fetchReimbursedAmountForClosingTransaction()
                    .subscribe(onSuccess: {[weak self] _ in
                        self?.bindLayout()
                    })
                    .disposed(by: disposeBag)
            default:
                bindLayout()
            }
        }
        
        private func bindLayout() {
            viewModel.transactionDriver
                .drive(onNext: { [weak self] transaction in
                    self?.layout(transaction: transaction)
                    self?.stackView.layoutIfNeeded()
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc private func showExplorer() {
            viewModel.showExplorer()
        }
        
        @objc func doneButtonDidTouch() {
            viewModel.markAsDone()
        }
        
        @objc func tryAgain() {
            viewModel.tryAgain()
        }
        
        @objc func cancel() {
            viewModel.cancel()
        }
        
        @objc func makeAnotherTransaction() {
            fatalError()
        }
    }
}
