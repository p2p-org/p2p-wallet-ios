//
//  ProcessTransaction.RootView+Layouts.swift
//  p2p_wallet
//
//  Created by Chung Tran on 02/06/2021.
//

import Foundation

extension ProcessTransaction.RootView {
    // MARK: - Main layout function
    func layoutWithTransactionType(
        _ transactionType: ProcessTransaction.TransactionType,
        transactionId: SolanaSDK.TransactionID?,
        transactionStatus: ProcessTransaction.TransactionStatus
    ) {
        // clean up
        amountLabel.isHidden = false
        equityAmountLabel.isHidden = false
        transactionIDStackView.isHidden = false
        
        layoutByDefault()
        
        // title, subtitle, image, button
        switch transactionStatus {
        case .processing:
            layoutProcessingTransaction(enableDoneButtonWhen: transactionId != nil)
        case .confirmed:
            layoutConfirmedTransaction()
        case .error(let error):
            layoutTransactionError(error, transactionType: transactionType)
        }
        
        // amount & equity value
        var symbol = ""
        var amount = 0.0
        switch transactionType {
        case .send(let fromWallet, _, let sentAmount):
            symbol = fromWallet.token.symbol
            amount = sentAmount
        }
        
        let equityValue = amount * viewModel.output.pricesRepository.currentPrice(for: symbol)?.value
        self.amountLabel.text = "\(amount.toString(maximumFractionDigits: 9, showPlus: true)) \(symbol)"
        self.equityAmountLabel.text = "\(equityValue.toString(maximumFractionDigits: 9, showPlus: true)) \(Defaults.fiat.symbol)"
        
        // transaction id
        if let signature = transactionId {
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
    
    private func layoutProcessingTransaction(enableDoneButtonWhen condition: Bool) {
        self.titleLabel.text = L10n.sending + "..."
        self.subtitleLabel.text = L10n.transactionProcessing
        self.transactionStatusImageView.image = .transactionProcessing
        self.buttonStackView.addArrangedSubview(
            WLButton.stepButton(type: .blue, label: L10n.done)
                .enableIf(condition)
                .onTap(self.viewModel, action: #selector(ProcessTransactionViewModel.done))
        )
    }
    
    private func layoutConfirmedTransaction() {
        self.titleLabel.text = L10n.success
        self.subtitleLabel.text = L10n.transactionHasBeenConfirmed
        self.transactionStatusImageView.image = .transactionSuccess
        self.buttonStackView.addArrangedSubview(
            WLButton.stepButton(type: .blue, label: L10n.done)
                .onTap(self.viewModel, action: #selector(ProcessTransactionViewModel.done))
        )
    }
    
    private func layoutTransactionError(_ error: Error, transactionType: ProcessTransaction.TransactionType) {
        // specific errors
        
        // When trying to send a wrapped token to a new SOL wallet (which is not yet in the blockchain)
        if error.readableDescription == L10n.invalidAccountInfo ||
            error.readableDescription == L10n.couldNotRetrieveAccountInfo
        {
            layoutWithSpecificError(
                image: .transactionErrorInvalidAccountInfo
            )
            
            titleLabel.text = L10n.invalidAccountInfo
            subtitleLabel.text = L10n.CheckEnteredAccountInfoForSending.itShouldBeAccountInSolanaNetwork
        }
        
        // When trying to send a wrapped token to another wrapped token
        else if error.readableDescription == L10n.walletAddressIsNotValid {
            layoutWithSpecificError(
                image: .transactionErrorWrongWallet
            )
            
            titleLabel.text = L10n.walletAddressIsNotValid
            
            var symbol = ""
            switch transactionType {
            case .send(let fromWallet, _, _):
                symbol = fromWallet.token.symbol
            }
            
            subtitleLabel.text = L10n.itMustBeAnWalletAddress(symbol)
        }
        
        // When a user entered an incorrect recipient address
        else if error.readableDescription == L10n.wrongWalletAddress
        {
            layoutWithSpecificError(
                image: .transactionErrorWrongWallet
            )
            
            titleLabel.text = L10n.wrongWalletAddress
            subtitleLabel.text = L10n.checkEnterredWalletAddressAndTryAgain
        }
        
        // When the user needs to correct the slippage value
        else if error.readableDescription == L10n.swapInstructionExceedsDesiredSlippageLimit
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
            .contains(error.readableDescription)
        {
            layoutWithSpecificError(
                image: .transactionErrorSystem
            )
            
            titleLabel.text = L10n.systemError
            subtitleLabel.text = error.readableDescription
        }
        
        // generic errors
        else {
            self.titleLabel.text = L10n.somethingWentWrong
            self.subtitleLabel.text = error.readableDescription
            self.transactionStatusImageView.image = .transactionError
            self.buttonStackView.addArrangedSubviews([
                WLButton.stepButton(type: .blue, label: L10n.tryAgain)
                    .onTap(self.viewModel, action: #selector(ProcessTransactionViewModel.tryAgain)),
                WLButton.stepButton(enabledColor: .eff3ff, textColor: .h5887ff, label: L10n.cancel)
                    .onTap(self.viewModel, action: #selector(ProcessTransactionViewModel.cancel))
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
            WLButton.stepButton(enabledColor: .eff3ff, textColor: .h5887ff, label: L10n.ok)
                .onTap(self.viewModel, action: #selector(ProcessTransactionViewModel.cancel))
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
}
