//
//  TransactionInfoRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import UIKit

class TransactionInfoRootView: ScrollableVStackRootView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: TransactionInfoViewModel
    
    // MARK: - Subviews
    private lazy var transactionTypeLabel = UILabel(textSize: 21, weight: .medium, textAlignment: .center)
    private lazy var transactionTimestampLabel = UILabel(textSize: 13, weight: .medium, textColor: .textSecondary, textAlignment: .center)
    private lazy var transactionIconImageView = UIImageView(width: 24, height: 24, tintColor: .white)
    private lazy var amountInFiatLabel = UILabel(textSize: 27, weight: .bold, textAlignment: .center)
    private lazy var amountInTokenLabel = UILabel(weight: .medium, textAlignment: .center)
    private lazy var statusLabel = UILabel(textSize: 12, weight: .bold, textColor: .textGreen)
    private lazy var sourcePubkeyLabel = UILabel(weight: .semibold)
    private lazy var destinationPubkeyLabel = UILabel(weight: .semibold)
    private lazy var amountDetailLabel = sectionContent()
    private lazy var valueLabel = sectionContent()
    private lazy var blockNumLabel = sectionContent()
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
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
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
            
            separator(),
            BEStackViewSpacing(20),
            
            // from
            sectionTitle(L10n.from),
            BEStackViewSpacing(20),
            UIView.row([
                UIView(width: 55, height: 55, backgroundColor: .c4c4c4, cornerRadius: 12),
                sourcePubkeyLabel,
                UIImageView(width: 24, height: 24, image: .copyToClipboard, tintColor: .a3a5ba)
                    .padding(.init(all: 6), backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.1), cornerRadius: 12)
                    .onTap(viewModel, action: #selector(TransactionInfoViewModel.copySourceAddressToClipboard))
            ])
                .with(spacing: 16, distribution: .fill)
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(20),
            
            separator(),
            BEStackViewSpacing(20),
            
            sectionTitle(L10n.to),
            BEStackViewSpacing(20),
            UIView.row([
                UIView(width: 55, height: 55, backgroundColor: .c4c4c4, cornerRadius: 12),
                destinationPubkeyLabel,
                UIImageView(width: 24, height: 24, image: .copyToClipboard, tintColor: .a3a5ba)
                    .padding(.init(all: 6), backgroundColor: UIColor.a3a5ba.withAlphaComponent(0.1), cornerRadius: 12)
                    .onTap(viewModel, action: #selector(TransactionInfoViewModel.copyDestinationAddressToClipboard))
            ])
                .with(spacing: 16, distribution: .fill)
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(20),
            
            separator(),
            BEStackViewSpacing(20),
            
            sectionTitle(L10n.amount.uppercaseFirst),
            BEStackViewSpacing(8),
            amountDetailLabel,
            BEStackViewSpacing(20),
            
            separator(),
            BEStackViewSpacing(20),
            
            sectionTitle(L10n.value),
            BEStackViewSpacing(8),
            valueLabel,
            BEStackViewSpacing(20),
            
            separator(),
            BEStackViewSpacing(20),
            
            sectionTitle(L10n.blockNumber),
            BEStackViewSpacing(8),
            blockNumLabel,
            BEStackViewSpacing(20),
            
            separator(),
            BEStackViewSpacing(20),
            
            sectionTitle(L10n.transactionID),
            BEStackViewSpacing(8),
            UIView.row([
                signatureLabel,
                UIImageView(width: 24, height: 24, image: .copyToClipboard, tintColor: .textBlack)
                    .onTap(viewModel, action: #selector(TransactionInfoViewModel.copySignatureToClipboard))
            ])
                .with(distribution: .fill)
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(20),
            
            separator(),
            BEStackViewSpacing(20),
            
            WLButton.stepButton(enabledColor: .f6f6f8, textColor: .a3a5ba, label: L10n.viewInBlockchainExplorer)
                .onTap(viewModel, action: #selector(TransactionInfoViewModel.showExplorer))
                .padding(.init(x: 20, y: 0))
        ])
    }
    
    private func bind() {
        
    }
    
    // MARK: - View builders
    fileprivate func separator() -> UIView {
        .separator(height: 1, color: UIColor.textBlack.withAlphaComponent(0.1))
    }
    
    fileprivate func sectionTitle(_ title: String?) -> UIView {
        UILabel(text: title, textSize: 12, weight: .semibold, textColor: .textSecondary)
            .padding(.init(x: 20, y: 0))
    }
    
    fileprivate func sectionContent() -> UIView {
        UILabel(weight: .semibold)
            .padding(.init(x: 20, y: 0))
    }
}
