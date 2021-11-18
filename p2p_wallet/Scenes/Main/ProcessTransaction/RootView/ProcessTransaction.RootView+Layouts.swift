//
//  ProcessTransaction.RootView+Layouts.swift
//  p2p_wallet
//
//  Created by Chung Tran on 02/06/2021.
//

import Foundation

extension ProcessTransaction.RootView {
    // MARK: - Main layout function
    func layout(transaction: SolanaSDK.ParsedTransaction) {
        // summary view
        summaryView?.removeFromSuperview()
        
        switch viewModel.transactionType {
        case .orcaSwap(let from, let to, let inputAmount, let estimatedAmount, _):
            let sv = SwapTransactionSummaryView(forAutoLayout: ())
            sv.setUp(from: from.token, to: to.token, inputAmount: inputAmount, estimatedAmount: estimatedAmount)
            summaryView = sv
        case .swap(_, let from, let to, let inputAmount, let estimatedAmount, _, _, _):
            let sv = SwapTransactionSummaryView(forAutoLayout: ())
            sv.setUp(from: from.token, to: to.token, inputAmount: inputAmount.toLamport(decimals: from.token.decimals), estimatedAmount: estimatedAmount.toLamport(decimals: to.token.decimals))
            summaryView = sv
        case .send(let fromWallet, _, let sentAmount, _):
            let sentAmount = -(sentAmount.convertToBalance(decimals: fromWallet.token.decimals))
            let symbol = fromWallet.token.symbol
            
            let sv = DefaultTransactionSummaryView(forAutoLayout: ())
            let equityValue = sentAmount * viewModel.pricesService.currentPrice(for: symbol)?.value
            sv.amountInTokenLabel.text = "\(sentAmount.toString(maximumFractionDigits: 9, showPlus: true)) \(symbol)"
            sv.amountInFiatLabel.text = "\(equityValue.toString(maximumFractionDigits: 9, showPlus: true)) \(Defaults.fiat.symbol)"
            
            summaryView = sv
        case .closeAccount:
            let amount = viewModel.reimbursedAmount ?? 0
            let symbol = "SOL"
            
            let sv = DefaultTransactionSummaryView(forAutoLayout: ())
            let equityValue = amount * viewModel.pricesService.currentPrice(for: symbol)?.value
            sv.amountInTokenLabel.text = "\(amount.toString(maximumFractionDigits: 9, showPlus: true)) \(symbol)"
            sv.amountInFiatLabel.text = "\(equityValue.toString(maximumFractionDigits: 9, showPlus: true)) \(Defaults.fiat.symbol)"
            
            summaryView = sv
        }
        transactionIDStackView.isHidden = false
        
        // default layout
        layoutByDefault()
        
        // title, subtitle, image, button
        switch transaction.status {
        case .requesting, .processing:
            layoutProcessingTransaction()
        case .confirmed:
            layoutConfirmedTransaction()
        case .error(let error):
            layoutTransactionError(error ?? L10n.somethingWentWrong)
        }
        
        // transaction id
        if let signature = transaction.signature {
            self.transactionIDLabel.text = signature
        } else {
            self.transactionIDStackView.isHidden = true
        }
    }
    
    // MARK: - Helpers
    private func layoutByDefault() {
        stackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
        buttonStackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
        stackView.addArrangedSubviews([
            titleLabel
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(5),
            subtitleLabel
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(20),
            createTransactionStatusView(),
            BEStackViewSpacing(15),
            summaryView,
            BEStackViewSpacing(30),
            UIView.defaultSeparator(),
            BEStackViewSpacing(20),
            transactionIDStackView,
            BEStackViewSpacing(20),
            buttonStackView
                .padding(.init(x: 20, y: 0))
        ])
    }
    
    private func layoutProcessingTransaction() {
        switch viewModel.transactionType {
        case .send, .closeAccount:
            self.titleLabel.text = L10n.sending + "..."
            self.subtitleLabel.text = L10n.transactionProcessing
        case .orcaSwap, .swap:
            self.titleLabel.text = L10n.swapping + "..."
            self.subtitleLabel.text = L10n.transactionProcessing
        }
        
        self.transactionStatusImageView.image = .transactionProcessing
        self.buttonStackView.addArrangedSubview(
            WLButton.stepButton(type: .blue, label: L10n.done)
                .onTap(self, action: #selector(doneButtonDidTouch))
        )
    }
    
    private func layoutConfirmedTransaction() {
        self.titleLabel.text = L10n.success
        self.subtitleLabel.text = L10n.transactionHasBeenConfirmed
        self.transactionStatusImageView.image = .transactionSuccess
        self.buttonStackView.addArrangedSubview(
            WLButton.stepButton(type: .blue, label: L10n.done)
                .onTap(self, action: #selector(doneButtonDidTouch))
        )
    }
    
    private func layoutTransactionError(_ error: String) {
        let transactionType = viewModel.transactionType
        // specific errors
        
        // When trying to send a wrapped token to a new SOL wallet (which is not yet in the blockchain)
        if error == L10n.invalidAccountInfo ||
            error == L10n.couldNotRetrieveAccountInfo
        {
            layoutWithSpecificError(
                image: .transactionErrorInvalidAccountInfo
            )
            
            titleLabel.text = L10n.invalidAccountInfo
            subtitleLabel.text = L10n.CheckEnteredAccountInfoForSending.itShouldBeAccountInSolanaNetwork
        }
        
        // When trying to send a wrapped token to another wrapped token
        else if error == L10n.walletAddressIsNotValid {
            layoutWithSpecificError(
                image: .transactionErrorWrongWallet
            )
            
            titleLabel.text = L10n.walletAddressIsNotValid
            
            var symbol = ""
            switch transactionType {
            case .send(let fromWallet, _, _, _):
                symbol = fromWallet.token.symbol
            case .orcaSwap, .swap, .closeAccount:
                break
            }
            
            subtitleLabel.text = L10n.itMustBeAnWalletAddress(symbol)
        }
        
        // When a user entered an incorrect recipient address
        else if error == L10n.wrongWalletAddress
        {
            layoutWithSpecificError(
                image: .transactionErrorWrongWallet
            )
            
            titleLabel.text = L10n.wrongWalletAddress
            subtitleLabel.text = L10n.checkEnterredWalletAddressAndTryAgain
        }
        
        // When the user needs to correct the slippage value
        else if error == L10n.swapInstructionExceedsDesiredSlippageLimit
        {
            layoutWithSpecificError(
                image: .transactionErrorSlippageExceeded
            )
            
            titleLabel.text = L10n.slippageError
            subtitleLabel.text = L10n.SwapInstructionExceedsDesiredSlippageLimit.setAnotherSlippageAndTryAgain
        }
        
        // System error
        else if [
            L10n.theFeeCalculationFailedDueToOverflowUnderflowOrUnexpected0,
            L10n.errorProcessingInstruction0CustomProgramError0x1,
            L10n.blockhashNotFound
        ]
            .contains(error)
        {
            layoutWithSpecificError(
                image: .transactionErrorSystem
            )
            
            titleLabel.text = L10n.systemError
            subtitleLabel.text = error
        }
        
        // generic errors
        else {
            self.titleLabel.text = L10n.somethingWentWrong
            self.subtitleLabel.text = error
            self.transactionStatusImageView.image = .transactionError
            self.buttonStackView.addArrangedSubviews([
                WLButton.stepButton(type: .blue, label: L10n.tryAgain)
                    .onTap(self, action: #selector(tryAgain)),
                createSecondaryButton(
                    label: L10n.cancel,
                    action: #selector(cancel)
                )
            ])
        }
    }
    
    private func layoutWithSpecificError(
        image: UIImage
    ) {
        stackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
        buttonStackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
        stackView.addArrangedSubviews([
            createTransactionStatusView(image: image),
            BEStackViewSpacing(30),
            titleLabel
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(5),
            subtitleLabel
                .padding(.init(x: 20, y: 0)),
            BEStackViewSpacing(64),
            buttonStackView
                .padding(.init(x: 20, y: 0))
        ])
        
        buttonStackView.addArrangedSubview(
            createSecondaryButton(
                label: L10n.ok,
                action: #selector(cancel)
            )
        )
    }
    
    private func createTransactionStatusView(image: UIImage = .transactionProcessing) -> UIView {
        let view = UIView(forAutoLayout: ())
        view.addSubview(transactionIndicatorView)
        transactionIndicatorView.autoPinEdge(toSuperviewEdge: .leading)
        transactionIndicatorView.autoPinEdge(toSuperviewEdge: .trailing)
        transactionIndicatorView.autoAlignAxis(toSuperviewAxis: .horizontal)
        view.addSubview(transactionStatusImageView)
        transactionStatusImageView.image = image
        transactionStatusImageView.autoPinEdge(toSuperviewEdge: .top)
        transactionStatusImageView.autoPinEdge(toSuperviewEdge: .bottom)
        transactionStatusImageView.autoAlignAxis(toSuperviewAxis: .vertical)
        return view
    }
    
    private func createSecondaryButton(label: String, action: Selector) -> WLButton {
        WLButton.stepButton(
            enabledColor: .eff3ff.onDarkMode(.h404040),
            textColor: .h5887ff.onDarkMode(.white),
            label: label
        )
            .onTap(self, action: action)
    }
}
