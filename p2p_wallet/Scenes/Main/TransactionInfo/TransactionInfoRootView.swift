//
//  TransactionInfoRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import UIKit
import RxSwift

class TransactionInfoRootView: ScrollableVStackRootView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: TransactionInfoViewModel
    let disposeBag = DisposeBag()
    
    // MARK: - Headers
    private lazy var transactionTypeLabel = UILabel(textSize: 21, weight: .medium, textAlignment: .center)
    private lazy var transactionTimestampLabel = UILabel(textSize: 13, weight: .medium, textColor: .textSecondary, textAlignment: .center)
    private lazy var transactionIconImageView = UIImageView(width: 24, height: 24, tintColor: .white)
    private lazy var amountInFiatLabel = UILabel(textSize: 27, weight: .bold, textAlignment: .center)
    private lazy var amountInTokenLabel = UILabel(weight: .medium, textAlignment: .center)
    private lazy var statusLabel = UILabel(textSize: 12, weight: .bold, textColor: .textGreen)
    
    // MARK: - Sections
    private lazy var transactionIdSection = createTransactionIdSection(signatureLabel: signatureLabel)
    
    private lazy var transactionFromSection = createLabelsOnlySection(title: L10n.from)
    
//    private lazy var sourcePubkeyLabel = UILabel(weight: .semibold)
//    private lazy var destinationPubkeyLabel = UILabel(weight: .semibold)
//    private lazy var amountDetailLabel = sectionContent()
//    private lazy var valueLabel = sectionContent()
//    private lazy var blockNumLabel = sectionContent()
    private lazy var signatureLabel = UILabel(weight: .semibold, numberOfLines: 0)
    
    // MARK: - Initializers
    init(viewModel: TransactionInfoViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }
    
    // MARK: - Methods
    override func commonInit() {
        super.commonInit()
        layout()
        bind()
    }
    
    // MARK: - Layout
    private func layout() {
        // header
        let headerView = UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill, arrangedSubviews: [
            // type
            transactionTypeLabel,
            // timestamp
            transactionTimestampLabel
        ])
            .padding(.init(top: 30, left: 20, bottom: 54, right: 20), backgroundColor: .f6f6f8)
        
        addSubview(headerView)
        headerView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        scrollView.contentInset.left = 0
        scrollView.contentInset.right = 0
        
        scrollView.constraintToSuperviewWithAttribute(.top)?.isActive = false
        headerView.autoPinEdge(.bottom, to: .top, of: scrollView)
        
        // icon
        
        addSubview(
            transactionIconImageView
                .padding(.init(all: 16), backgroundColor: .h5887ff, cornerRadius: 12)
        )
        transactionIconImageView.wrapper?.autoAlignAxis(toSuperviewAxis: .vertical)
        transactionIconImageView.wrapper?.autoPinEdge(.top, to: .bottom, of: headerView, withOffset: -28)
        
        // content inset
        scrollView.contentInset.modify(dTop: 58)
        
        // setup content
        stackView.spacing = 0
        
        stackView.addArrangedSubviews([
            // amount in usd
            amountInFiatLabel
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(5),
            
            // amount
            amountInTokenLabel
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(20),
            
            // status
            statusLabel
                .padding(.init(x: 16, y: 8), backgroundColor: UIColor.attentionGreen.withAlphaComponent(0.3), cornerRadius: 10)
                .centeredHorizontallyView,
            BEStackViewSpacing(30),
            
            // sections
            transactionFromSection,
            transactionIdSection,
            
            // buttons
            UIView.separator(height: 1, color: .separator),
            BEStackViewSpacing(20),
            
            WLButton.stepButton(enabledColor: .f6f6f8, textColor: .a3a5ba, label: L10n.viewInBlockchainExplorer)
                .onTap(viewModel, action: #selector(TransactionInfoViewModel.showExplorer))
                .padding(.init(x: 20, y: 0))
        ])
    }
    
    private func bind() {
        let transactionDriver = viewModel.transaction.asDriver()
        
        transactionDriver
            .map {$0.symbol}
            .drive(transactionFromSection.contentView.rx.text)
            .disposed(by: disposeBag)
        
        transactionDriver
            .map {$0.signature}
            .drive(signatureLabel.rx.text)
            .disposed(by: disposeBag)
    }
}

// MARK: - View builders
extension TransactionInfoRootView {
    func createLabelsOnlySection(title: String) -> TransactionInfoSection<UILabel, UILabel>
    {
        TransactionInfoSection(
            titleView: createSectionTitle(title),
            contentView: createContentLabel()
        )
    }
    
    func createTransactionIdSection(signatureLabel: UILabel) -> TransactionInfoSection<UILabel, UIStackView>
    {
        TransactionInfoSection(
            titleView: createSectionTitle(L10n.transactionID),
            contentView: UIStackView(
                axis: .horizontal,
                spacing: 16,
                alignment: .center,
                distribution: .fill,
                arrangedSubviews: [
                    signatureLabel,
                    UIImageView(width: 16, height: 16, image: .link, tintColor: .a3a5ba)
                        .padding(.init(all: 10), backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.1), cornerRadius: 12)
                        .onTap(viewModel, action: #selector(TransactionInfoViewModel.showExplorer))
                ]
            )
        )
    }
    
    private func createSectionTitle(_ title: String?) -> UILabel {
        UILabel(text: title, textSize: 12, weight: .semibold, textColor: .textSecondary)
    }
    
    private func createContentLabel() -> UILabel {
        UILabel(weight: .semibold)
    }
}
