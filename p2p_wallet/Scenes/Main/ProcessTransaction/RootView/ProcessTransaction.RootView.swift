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
        var transactionStatusDidChange: (() -> Void)?
        
        // MARK: - Subviews
        lazy var stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)
        lazy var titleLabel = UILabel(textSize: 21, weight: .semibold, numberOfLines: 0, textAlignment: .center)
        lazy var subtitleLabel = UILabel(weight: .medium, textColor: .textSecondary, numberOfLines: 0, textAlignment: .center)
        lazy var transactionStatusImageView = UIImageView(width: 65, height: 65, image: .transactionProcessing)
        lazy var transactionIndicatorView: TransactionIndicatorView = {
            let indicatorView = TransactionIndicatorView(height: 1, backgroundColor: .separator)
            indicatorView.tintColor = .h5887ff
            return indicatorView
        }()
        var summaryView: TransactionSummaryView!
        lazy var transactionIDLabel = UILabel(weight: .semibold, numberOfLines: 2)
        
        // MARK: - Substackviews
        lazy var transactionIDStackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill, arrangedSubviews: [
            UILabel(text: L10n.transactionID, textSize: 13, weight: .medium, textColor: .textSecondary)
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(8),
            UIStackView(axis: .horizontal, spacing: 16, alignment: .center, distribution: .fill) {
                transactionIDLabel
                
                UIImageView(width: 16, height: 16, image: .link, tintColor: .a3a5ba)
                    .padding(.init(all: 10), backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.1), cornerRadius: 12)
                    .onTap(self, action: #selector(showExplorer))
            }
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(20),
            UIView.defaultSeparator()
        ])
        lazy var buttonStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)
        
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
                    self?.transactionStatusDidChange?()
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
    }
}
