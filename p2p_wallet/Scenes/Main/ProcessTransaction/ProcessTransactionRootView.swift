//
//  ProcessTransactionRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/03/2021.
//

import UIKit
import RxSwift

class TransactionIndicatorView: BEView {
    public var percent: CGFloat = 0.0 {
        didSet {
            indicatorViewWidthConstraint = indicatorViewWidthConstraint?.setMultiplier(multiplier: percent)
            indicatorView.setNeedsLayout()
        }
    }
    
    override public var tintColor: UIColor! {
        didSet {
            indicatorView.backgroundColor = tintColor
        }
    }
    
    private lazy var indicatorView = UIView(backgroundColor: tintColor)
    private var indicatorViewWidthConstraint: NSLayoutConstraint?
    
    override func commonInit() {
        super.commonInit()
        
        addSubview(indicatorView)
        indicatorView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .trailing)
        
        indicatorViewWidthConstraint = indicatorView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0)
            
        indicatorViewWidthConstraint?.isActive = true
    }
}

class ProcessTransactionRootView: BEView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: ProcessTransactionViewModel
    let disposeBag = DisposeBag()
    var transactionDidChange: (() -> Void)?
    
    // MARK: - Subviews
    lazy var stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)
    lazy var titleLabel = UILabel(textSize: 21, weight: .semibold, textAlignment: .center)
    lazy var subtitleLabel = UILabel(weight: .medium, textColor: .textSecondary, textAlignment: .center)
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
    lazy var buttonStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
        WLButton.stepButton(type: .blue, label: "test")
    ])
    
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
        stackView.addArrangedSubviews([
            titleLabel,
            BEStackViewSpacing(5),
            subtitleLabel,
            BEStackViewSpacing(20),
            createTransactionStatusView(),
            BEStackViewSpacing(15),
            amountLabel,
            BEStackViewSpacing(5),
            equityAmountLabel,
            BEStackViewSpacing(30),
            UIView.separator(height: 1, color: .separator),
            BEStackViewSpacing(20),
            transactionIDStackView,
            BEStackViewSpacing(20),
            buttonStackView
                .padding(.init(x: 20, y: 0))
        ])
    }
    
    private func bind() {
        viewModel.transaction
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: {[unowned self] transaction in
                self.amountLabel.isHidden = false
                self.equityAmountLabel.isHidden = false
                self.transactionIDStackView.isHidden = false
                if let transaction = transaction {
                    switch transaction.status {
                    case .processing:
                        self.titleLabel.text = L10n.sending + "..."
                        self.subtitleLabel.text = L10n.transactionProcessing
                        self.transactionStatusImageView.image = .transactionProcessing
                    case .confirmed:
                        self.titleLabel.text = L10n.success
                        self.subtitleLabel.text = L10n.transactionHasBeenConfirmed
                        self.transactionStatusImageView.image = .transactionSuccess
                    }
                    self.amountLabel.text = "\(transaction.amount.toString(maximumFractionDigits: 9, showPlus: true)) \(transaction.symbol)"
                    self.equityAmountLabel.text = "\(transaction.amountInUSD.toString(maximumFractionDigits: 9, showPlus: true)) $"
                    self.transactionIDLabel.text = transaction.signature
                } else {
                    self.titleLabel.text = L10n.sending + "..."
                    self.subtitleLabel.text = L10n.transactionProcessing
                    self.amountLabel.isHidden = true
                    self.equityAmountLabel.isHidden = true
                    self.transactionIDStackView.isHidden = true
                }
                
                self.transactionDidChange?()
            })
            .disposed(by: disposeBag)
    }
    
    private func createTransactionStatusView() -> UIView {
        let view = UIView(forAutoLayout: ())
        view.addSubview(transactionIndicatorView)
        transactionIndicatorView.autoPinEdge(toSuperviewEdge: .leading)
        transactionIndicatorView.autoPinEdge(toSuperviewEdge: .trailing)
        transactionIndicatorView.autoAlignAxis(toSuperviewAxis: .horizontal)
        view.addSubview(transactionStatusImageView)
        transactionStatusImageView.autoPinEdge(toSuperviewEdge: .top)
        transactionStatusImageView.autoPinEdge(toSuperviewEdge: .bottom)
        transactionStatusImageView.autoAlignAxis(toSuperviewAxis: .vertical)
        return view
    }
}
