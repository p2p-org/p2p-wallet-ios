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
    lazy var headerView = UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill, arrangedSubviews: [
        // type
        transactionTypeLabel,
        // timestamp
        transactionTimestampLabel
    ])
        .padding(.init(top: 30, left: 20, bottom: 54, right: 20))
    private lazy var transactionTypeLabel = UILabel(textSize: 21, weight: .semibold, textAlignment: .center)
    private lazy var transactionTimestampLabel = UILabel(textSize: 13, weight: .medium, textColor: .textSecondary, textAlignment: .center)
    private lazy var transactionIconImageView = UIImageView(width: 30, height: 30, tintColor: .white)
    
    // MARK: - SummaryViews
    private lazy var defaultSummaryView = DefaultTransactionSummaryView(forAutoLayout: ())
    private lazy var swapSummaryView = SwapTransactionSummaryView(forAutoLayout: ())
    
    // MARK: - Status view
    private lazy var statusView = TransactionStatusView()
    
    // MARK: - Sections
    private lazy var transactionDetailView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill)
    private lazy var transactionIdSection = createTransactionIdSection(signatureLabel: signatureLabel)
    private lazy var blockNumSection = createLabelsOnlySection(title: L10n.blockNumber)
    private lazy var feeSection = createFeeSection()
    
//    private lazy var transactionFromSection = createLabelsOnlySection(title: L10n.from)
    
//    private lazy var sourcePubkeyLabel = UILabel(weight: .semibold)
//    private lazy var destinationPubkeyLabel = UILabel(weight: .semibold)
//    private lazy var amountDetailLabel = sectionContent()
//    private lazy var valueLabel = sectionContent()
//    private lazy var blockNumLabel = sectionContent()
    private lazy var signatureLabel = UILabel(weight: .semibold, numberOfLines: 0)
    
    private lazy var toggleShowHideTransactionDetailsButton = WLButton.stepButton(enabledColor: .grayPanel, textColor: .a3a5baStatic.onDarkMode(.white), label: L10n.showTransactionDetails)
    
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
        addSubview(headerView)
        headerView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        // configure scroll view
        scrollView.contentInset.left = 0
        scrollView.contentInset.right = 0
        scrollView.contentInset.top = 56
        scrollView.contentInset.bottom = 20
        
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
        let separator = UIView.defaultSeparator()
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
            UIView.defaultSeparator(),
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
                let transaction = transaction.parsed
                self?.transactionTypeLabel.text = transaction?.label
                self?.transactionTimestampLabel.text = transaction?.blockTime?.string(withFormat: "dd MMM yyyy @ HH:mm a")
                self?.transactionIconImageView.image = transaction?.icon
            })
            .disposed(by: disposeBag)
        
        // setUp
        transactionDriver
            .drive(onNext: {[weak self] transaction in
                self?.setUp(transaction: transaction.parsed)
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
            .map {$0.parsed?.signature}
            .drive(signatureLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    private func setUp(transaction: SolanaSDK.AnyTransaction?) {
        guard let transaction = transaction else {return}
        // summary
        if let summaryView = stackView.arrangedSubviews.first as? TransactionSummaryView
        {
            summaryView.superview?.removeFromSuperview()
        }
        
        // transaction detail view
        transactionDetailView.arrangedSubviews.forEach {$0.removeFromSuperview()}
        
        // if detail shown
        blockNumSection.contentView.text = "#\(transaction.slot ?? 0)"
        feeSection.contentView.text = "\(transaction.fee ?? 0)" + " lamports"
        
        // modify
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
        swapSummaryView.sourceIconImageView.setUp(token: transaction.source?.token)
        swapSummaryView.sourceAmountLabel.text = (-(transaction.sourceAmount ?? 0)).toString(maximumFractionDigits: 4)
        swapSummaryView.sourceSymbolLabel.text = transaction.source?.token.symbol
        
        swapSummaryView.destinationIconImageView.setUp(token: transaction.destination?.token)
        swapSummaryView.destinationAmountLabel.text = transaction.destinationAmount?.toString(maximumFractionDigits: 4, showPlus: true)
        swapSummaryView.destinationSymbolLabel.text = transaction.destination?.token.symbol
        
        let fromSection = createLabelsOnlySection(title: L10n.from)
        fromSection.contentView.text = transaction.source?.pubkey
        
        let toSection = createLabelsOnlySection(title: L10n.to)
        toSection.contentView.text = transaction.destination?.pubkey
        
        let amountSection = createLabelsOnlySection(title: L10n.amount.uppercaseFirst)
        var amountText: String = transaction.sourceAmount
            .toString(maximumFractionDigits: 4, showMinus: false)
        
        amountText += " "
        amountText += transaction.source?.token.symbol ?? ""
        amountText += " \(L10n.to.lowercased()) "
        amountText += transaction.destinationAmount
            .toString(maximumFractionDigits: 4, showMinus: false)
        amountText += " "
        amountText += transaction.destination?.token.symbol ?? ""
        
        amountSection.contentView.text = amountText
        
        transactionDetailView.addArrangedSubviews([
            fromSection,
            toSection,
            amountSection,
            feeSection,
            blockNumSection
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
        
        defaultSummaryView.amountInFiatLabel.text = transaction.amountInFiat.toString(maximumFractionDigits: 4, showPlus: true) + " " + Defaults.fiat.symbol
        defaultSummaryView.amountInTokenLabel.text = transaction.amount.toString(maximumFractionDigits: 4, showPlus: true) + " " + transaction.symbol
        
        // disable fee for receive action
        var shouldAddFeeSection = true
        var wasPaidByP2POrg = false
        
        switch transaction.value {
        case let transferTransaction as SolanaSDK.TransferTransaction:
            var fromIconView: UIView?
            var toIconView: UIView?
            let coinLogoImageView = CoinLogoImageView(size: 45)
            wasPaidByP2POrg = transferTransaction.wasPaidByP2POrg
            
            switch transferTransaction.transferType {
            case .send:
                coinLogoImageView.setUp(token: transferTransaction.source?.token)
                
                fromIconView = coinLogoImageView
                toIconView = UIImageView(width: 25, height: 25, image: .walletIcon, tintColor: .iconSecondary)
                    .padding(.init(all: 10), backgroundColor: .grayPanel, cornerRadius: 12)
                
            case .receive:
                shouldAddFeeSection = false
                fromIconView = UIImageView(width: 25, height: 25, image: .walletIcon, tintColor: .iconSecondary)
                    .padding(.init(all: 10), backgroundColor: .grayPanel, cornerRadius: 12)
                coinLogoImageView.setUp(token: transferTransaction.destination?.token)
                toIconView = coinLogoImageView
            default:
                fromIconView = UIImageView(width: 25, height: 25, image: .walletIcon, tintColor: .iconSecondary)
                    .padding(.init(all: 10), backgroundColor: .grayPanel, cornerRadius: 12)
                
                toIconView = UIImageView(width: 25, height: 25, image: .walletIcon, tintColor: .iconSecondary)
                    .padding(.init(all: 10), backgroundColor: .grayPanel, cornerRadius: 12)
            }
            
            transactionDetailView.addArrangedSubviews([
                createWalletInfo(
                    title: L10n.from,
                    iconView: fromIconView,
                    wallet: transferTransaction.source,
                    selector: #selector(
                        TransactionInfoViewModel.copySourceAddressToClipboard
                    )
                ),
                createWalletInfo(
                    title: L10n.to,
                    iconView: toIconView,
                    wallet: transferTransaction.destination,
                    selector: #selector(
                        TransactionInfoViewModel.copyDestinationAddressToClipboard
                    )
                )
            ])
            
        case let createAccountTransaction as SolanaSDK.CreateAccountTransaction:
            transactionDetailView.addArrangedSubviews([
                createWalletInfo(
                    title: L10n.newWallet,
                    iconView: CoinLogoImageView(size: 45)
                        .with(token: createAccountTransaction.newWallet?.token),
                    wallet: createAccountTransaction.newWallet,
                    selector: #selector(
                        TransactionInfoViewModel.copyDestinationAddressToClipboard
                    )
                )
            ])
        case let closedAccountTransaction as SolanaSDK.CloseAccountTransaction:
            transactionDetailView.addArrangedSubviews([
                createWalletInfo(
                    title: L10n.closedWallet,
                    iconView: CoinLogoImageView(size: 45)
                        .with(token: closedAccountTransaction.closedWallet?.token),
                    wallet: closedAccountTransaction.closedWallet
                )
            ])
        default:
            break
        }
        
        transactionDetailView.addArrangedSubviews([
            createLabelsOnlySection(
                title: L10n.amount.uppercaseFirst,
                content: transaction.amount.toString(maximumFractionDigits: 9, showMinus: false) + " " + transaction.symbol
            ),
            createLabelsOnlySection(
                title: L10n.value,
                content: "\(Defaults.fiat.symbol) " + transaction.amountInFiat?.toString(maximumFractionDigits: 9, showMinus: false)
            )
        ])
        
        if shouldAddFeeSection {
            transactionDetailView.addArrangedSubview(feeSection)
            feeSection.titleView.arrangedSubviews.first(where: {$0.tag == 2})?.isHidden = !wasPaidByP2POrg
        }
        transactionDetailView.addArrangedSubview(blockNumSection)
    }
}

// MARK: - View builders
private extension TransactionInfoRootView {
    func createLabelsOnlySection(title: String, content: String? = nil) -> TransactionInfoSection<UILabel, UILabel>
    {
        let section = TransactionInfoSection(
            titleView: createSectionTitle(title),
            contentView: createContentLabel()
        )
        section.contentView.text = content
        return section
    }
    
    func createFeeSection() -> TransactionInfoSection<UIStackView, UILabel>
    {
        TransactionInfoSection(
            titleView: UIStackView(axis: .horizontal, spacing: 10, alignment: .center, distribution: .equalSpacing, builder: {
                createSectionTitle(L10n.fee)
                
                UILabel(text: L10n.PaidByP2p.org, textSize: 13, weight: .semibold, textColor: .h5887ff)
                    .padding(.init(x: 8, y: 2), backgroundColor: .eff3ff, cornerRadius: 4)
                    .withTag(2)
                    .hidden()
            }),
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
                    UIImageView(width: 16, height: 16, image: .link, tintColor: .iconSecondary)
                        .padding(
                            .init(all: 10),
                            backgroundColor:
                                UIColor.a3a5ba.withAlphaComponent(0.1).onDarkMode(.grayPanel),
                            cornerRadius: 12
                        )
                        .onTap(viewModel, action: #selector(TransactionInfoViewModel.showExplorer))
                ]
            )
        )
    }
    
    func createWalletInfo(
        title: String,
        iconView: UIView?,
        wallet: Wallet?,
        selector: Selector? = nil
    ) -> TransactionInfoSection<UILabel, UIStackView> {
        var arrangedSubviews: [BEStackViewElement] = []
        
        if let iconView = iconView {
            arrangedSubviews.append(iconView)
        }
        
        arrangedSubviews.append(
            UIStackView(axis: .vertical, spacing: 7, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UILabel(text: wallet?.token.symbol, textSize: 17, weight: .semibold),
                UILabel(text: wallet?.shortPubkey(), weight: .semibold, textColor: .textSecondary)
            ])
        )
        
        if let selector = selector {
            arrangedSubviews.append(
                UIImageView(width: 24, height: 24, image: .copyToClipboard, tintColor: .iconSecondary)
                    .padding(
                        .init(all: 6),
                        backgroundColor:
                            UIColor.a3a5ba.withAlphaComponent(0.1).onDarkMode(.grayPanel),
                        cornerRadius: 12
                    )
                    .onTap(viewModel, action: selector)
            )
        }
        let section = TransactionInfoSection(
            titleView: createSectionTitle(title),
            contentView: UIStackView(
                axis: .horizontal,
                spacing: 16,
                alignment: .center,
                distribution: .fill,
                arrangedSubviews: arrangedSubviews
            )
        )
        section.spacing = 20
        return section
    }
    
    func createSectionTitle(_ title: String?) -> UILabel {
        UILabel(text: title, textSize: 13, weight: .medium, textColor: .textSecondary)
    }
    
    func createContentLabel() -> UILabel {
        UILabel(weight: .semibold, numberOfLines: 0)
    }
}
