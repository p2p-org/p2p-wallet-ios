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
        stackView.addArrangedSubviews([
            titleLabel,
            BEStackViewSpacing(5),
            subtitleLabel
                .padding(.init(x: 20, y: 0)),
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
        viewModel.transactionHandler
            .asDriver(onErrorJustReturn: TransactionHandler(transaction: nil, error: nil))
            .drive(onNext: {[unowned self] transactionHandler in
                self.amountLabel.isHidden = false
                self.equityAmountLabel.isHidden = false
                self.transactionIDStackView.isHidden = false
                self.buttonStackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
                
                // title, subtitle, image, button
                if let error = transactionHandler.error {
                    self.titleLabel.text = L10n.somethingWentWrong
                    self.subtitleLabel.text = error.readableDescription
                    self.transactionStatusImageView.image = .transactionError
                    self.buttonStackView.addArrangedSubviews([
                        WLButton.stepButton(type: .blue, label: L10n.tryAgain)
                            .onTap(self.viewModel, action: #selector(ProcessTransactionViewModel.tryAgain)),
                        WLButton.stepButton(type: .sub, label: L10n.cancel)
                            .onTap(self.viewModel, action: #selector(ProcessTransactionViewModel.cancel))
                    ])
                } else if let transaction = transactionHandler.transaction {
                    switch transaction.status {
                    case .processing:
                        self.titleLabel.text = L10n.sending + "..."
                        self.subtitleLabel.text = L10n.transactionProcessing
                        self.transactionStatusImageView.image = .transactionProcessing
                        self.buttonStackView.addArrangedSubviews([
                            WLButton.stepButton(enabledColor: .f6f6f8, textColor: .a3a5baStatic, label: L10n.viewInBlockchainExplorer)
                                .enableIf(self.viewModel.transaction?.signature != nil)
                                .onTap(self.viewModel, action: #selector(ProcessTransactionViewModel.viewInExplorer)),
                            WLButton.stepButton(type: .blue, label: L10n.done)
                                .enableIf(self.viewModel.transaction?.signature != nil)
                                .onTap(self.viewModel, action: #selector(ProcessTransactionViewModel.done))
                        ])
                    case .confirmed:
                        self.titleLabel.text = L10n.success
                        self.subtitleLabel.text = L10n.transactionHasBeenConfirmed
                        self.transactionStatusImageView.image = .transactionSuccess
                        self.buttonStackView.addArrangedSubviews([
                            WLButton.stepButton(enabledColor: .f6f6f8, textColor: .a3a5baStatic, label: L10n.viewInBlockchainExplorer)
                                .enableIf(self.viewModel.transaction?.signature != nil)
                                .onTap(self.viewModel, action: #selector(ProcessTransactionViewModel.viewInExplorer)),
                            WLButton.stepButton(type: .blue, label: L10n.done)
                                .enableIf(self.viewModel.transaction?.signature != nil)
                                .onTap(self.viewModel, action: #selector(ProcessTransactionViewModel.done))
                        ])
                    }
                } else {
                    self.titleLabel.text = L10n.sending + "..."
                    self.subtitleLabel.text = L10n.transactionProcessing
                    self.transactionStatusImageView.image = .transactionProcessing
                }
                
                // amount & equity value
                if let amount = transactionHandler.transaction?.amount,
                   let equityValue = transactionHandler.transaction?.amountInUSD,
                   let symbol = transactionHandler.transaction?.symbol
                {
                    self.amountLabel.text = "\(amount.toString(maximumFractionDigits: 9, showPlus: true)) \(symbol)"
                    self.equityAmountLabel.text = "\(equityValue.toString(maximumFractionDigits: 9, showPlus: true)) $"
                } else {
                    self.amountLabel.isHidden = true
                    self.equityAmountLabel.isHidden = true
                }
                
                // transaction id
                if let signature = transactionHandler.transaction?.signature {
                    self.transactionIDLabel.text = signature
                } else {
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
