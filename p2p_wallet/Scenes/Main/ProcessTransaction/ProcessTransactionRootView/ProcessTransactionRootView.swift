//
//  ProcessTransactionRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/03/2021.
//

import UIKit
import RxSwift

class ProcessTransactionRootView: BEView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: ProcessTransactionViewModel
    let disposeBag = DisposeBag()
    var transactionDidChange: (() -> Void)?
    
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
    lazy var amountLabel = UILabel(textSize: 27, weight: .bold, textAlignment: .center)
    lazy var equityAmountLabel = UILabel(textColor: .textSecondary, textAlignment: .center)
    lazy var transactionIDLabel = UILabel(weight: .semibold)
    
    // MARK: - Substackviews
    lazy var transactionIDStackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill, arrangedSubviews: [
        UILabel(text: L10n.transactionID, textSize: 13, weight: .medium, textColor: .textSecondary)
            .padding(.init(x: 20, y: 0)),
        BEStackViewSpacing(8),
        transactionIDLabel
            .padding(.init(x: 20, y: 0)),
        BEStackViewSpacing(20),
        UIView.separator(height: 1, color: .separator)
    ])
    lazy var buttonStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill)
    
    // MARK: - Initializers
    init(viewModel: ProcessTransactionViewModel) {
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
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 0, y: 30))
        
        stackView.spacing = 0
    }
    
    private func bind() {
        viewModel.transactionInfo
            .asDriver(onErrorJustReturn: TransactionInfo(transaction: nil, error: nil))
            .drive(onNext: {[weak self] transactionHandler in
                self?.layout(transactionHandler: transactionHandler)
                self?.transactionDidChange?()
            })
            .disposed(by: disposeBag)
    }
}
