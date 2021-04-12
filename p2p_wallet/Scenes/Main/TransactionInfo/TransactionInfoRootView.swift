//
//  TransactionInfoRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/04/2021.
//

import UIKit
import RxSwift

class TransactionInfoRootView: IntrinsicScrollableVStackRootView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: TransactionInfoViewModel
    let disposeBag = DisposeBag()
    
    // MARK: - Headers
    private lazy var transactionTypeLabel = UILabel(textSize: 21, weight: .medium, textAlignment: .center)
    private lazy var transactionTimestampLabel = UILabel(textSize: 13, weight: .medium, textColor: .textSecondary, textAlignment: .center)
    private lazy var transactionIconImageView = UIImageView(width: 30, height: 30, tintColor: .white)
    
    // MARK: - SummaryViews
    private lazy var defaultSummaryView = DefaultSummaryView(forAutoLayout: ())
    private lazy var swapSummaryView = SwapSummaryView(forAutoLayout: ())
    
    // MARK: - Status view
    private lazy var statusView = TransactionStatusView()
    
    // MARK: - Sections
    private lazy var transactionDetailView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill)
    private lazy var transactionIdSection = createTransactionIdSection(signatureLabel: signatureLabel)
    
//    private lazy var transactionFromSection = createLabelsOnlySection(title: L10n.from)
    
//    private lazy var sourcePubkeyLabel = UILabel(weight: .semibold)
//    private lazy var destinationPubkeyLabel = UILabel(weight: .semibold)
//    private lazy var amountDetailLabel = sectionContent()
//    private lazy var valueLabel = sectionContent()
//    private lazy var blockNumLabel = sectionContent()
    private lazy var signatureLabel = UILabel(weight: .semibold, numberOfLines: 0)
    
    private lazy var toggleShowHideTransactionDetailsButton = WLButton.stepButton(enabledColor: .f6f6f8, textColor: .a3a5ba, label: L10n.showTransactionDetails)
    
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
            .padding(.init(top: 30, left: 20, bottom: 54, right: 20))
        
        addSubview(headerView)
        headerView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        // configure scroll view
        scrollView.contentInset.left = 0
        scrollView.contentInset.right = 0
        scrollView.contentInset.top = 56
        
        scrollView.constraintToSuperviewWithAttribute(.top)?.isActive = false
        headerView.autoPinEdge(.bottom, to: .top, of: scrollView)
        
        // icon
        addSubview(
            transactionIconImageView
                .padding(.init(all: 16), backgroundColor: .h5887ff, cornerRadius: 12)
        )
        transactionIconImageView.wrapper?.autoAlignAxis(toSuperviewAxis: .vertical)
        transactionIconImageView.wrapper?.autoPinEdge(.top, to: .bottom, of: headerView, withOffset: -28)
        
        // separator
        let separator = UIView.separator(height: 1, color: .separator)
        addSubview(separator)
        separator.autoPinEdge(toSuperviewEdge: .leading)
        separator.autoPinEdge(toSuperviewEdge: .trailing)
        separator.autoAlignAxis(.horizontal, toSameAxisOf: transactionIconImageView)
        
        // setup content
        stackView.spacing = 0
        
        stackView.addArrangedSubviews([
            // status
            statusView.centeredHorizontallyView,
            
            BEStackViewSpacing(30),
            
            // detail
            transactionDetailView,
            
            // sections
            transactionIdSection,
            
            // buttons
            UIView.separator(height: 1, color: .separator),
            BEStackViewSpacing(20),
            
            toggleShowHideTransactionDetailsButton
                .onTap(viewModel, action: #selector(TransactionInfoViewModel.toggleShowDetailTransaction))
                .padding(.init(x: 20, y: 0))
        ])
    }
    
    private func bind() {
        let transactionDriver = viewModel.transaction.asDriver()
        let showDetailTransactionDriver = viewModel.showDetailTransaction.asDriver()
        
        // header
        transactionDriver
            .drive(onNext: {[weak self] transaction in
                self?.transactionTypeLabel.text = transaction.label
                // TODO: - Date
                self?.transactionIconImageView.image = transaction.icon
            })
            .disposed(by: disposeBag)
        
        // setUp
        transactionDriver
            .drive(onNext: {[weak self] transaction in
                self?.setUp(transaction: transaction)
            })
            .disposed(by: disposeBag)
        
        // detail
        showDetailTransactionDriver
            .map {!$0}
            .drive(transactionDetailView.rx.isHidden)
            .disposed(by: disposeBag)
        
        showDetailTransactionDriver
            .map {$0 ? L10n.hideTransactionDetails: L10n.showTransactionDetails}
            .drive(toggleShowHideTransactionDetailsButton.rx.title(for: .normal))
            .disposed(by: disposeBag)
        
        // signature
        transactionDriver
            .map {$0.signature}
            .drive(signatureLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    private func setUp(transaction: SolanaSDK.AnyTransaction) {
        if let summaryView = stackView.arrangedSubviews.first as? SummaryView
        {
            summaryView.superview?.removeFromSuperview()
        }
        transactionDetailView.arrangedSubviews.forEach {$0.removeFromSuperview()}
        switch transaction.value {
        case let transaction as SolanaSDK.SwapTransaction:
            setUpWithSwapTransaction(transaction)
        default:
            setUpWithOtherTransaction(transaction)
        }
    }
    
    private func setUpWithSwapTransaction(_ transaction: SolanaSDK.SwapTransaction)
    {
        var index = 0
        stackView.insertArrangedSubviewsWithCustomSpacing(
            [
                swapSummaryView,
                BEStackViewSpacing(24)
            ],
            at: &index
        )
        swapSummaryView.sourceIconImageView.setUp(token: transaction.source)
        swapSummaryView.sourceAmountLabel.text = transaction.sourceAmount?.toString(maximumFractionDigits: 4, showPlus: true)
        swapSummaryView.sourceSymbolLabel.text = transaction.source?.symbol
        
        swapSummaryView.destinationIconImageView.setUp(token: transaction.destination)
        swapSummaryView.destinationAmountLabel.text = transaction.destinationAmount?.toString(maximumFractionDigits: 4, showPlus: true)
        swapSummaryView.destinationSymbolLabel.text = transaction.destination?.symbol
        
        let fromSection = createLabelsOnlySection(title: L10n.from)
        fromSection.contentView.text = transaction.source?.pubkey
        
        let toSection = createLabelsOnlySection(title: L10n.to)
        toSection.contentView.text = transaction.destination?.pubkey
        
        let amountSection = createLabelsOnlySection(title: L10n.amount.uppercaseFirst)
        amountSection.contentView.text =
            transaction.sourceAmount
                .toString(maximumFractionDigits: 4, showMinus: false)
            + " "
            + transaction.source?.symbol
            + " \(L10n.to.lowercased()) "
            + transaction.destinationAmount
                .toString(maximumFractionDigits: 4, showMinus: false)
        
        transactionDetailView.addArrangedSubviews([
            fromSection,
            toSection,
            amountSection
        ])
    }
    
    private func setUpWithOtherTransaction(_ transaction: SolanaSDK.AnyTransaction)
    {
        var index = 0
        stackView.insertArrangedSubviewsWithCustomSpacing(
            [
                defaultSummaryView,
                BEStackViewSpacing(24)
            ],
            at: &index
        )
        
        defaultSummaryView.amountInFiatLabel.text = transaction.amountInFiat.toString(maximumFractionDigits: 4, showPlus: true) + " $"
        defaultSummaryView.amountInTokenLabel.text = transaction.amount.toString(maximumFractionDigits: 4, showPlus: true) + " " + transaction.symbol
        
        transactionDetailView.addArrangedSubviews([
            
        ])
    }
}

// MARK: - View builders
private extension TransactionInfoRootView {
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
    
    func createSectionTitle(_ title: String?) -> UILabel {
        UILabel(text: title, textSize: 13, weight: .medium, textColor: .textSecondary)
    }
    
    func createContentLabel() -> UILabel {
        UILabel(weight: .semibold, numberOfLines: 0)
    }
}
