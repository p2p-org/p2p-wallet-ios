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
        @unknown default:
            fatalError()
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
        stackView.addArrangedSubviews([
            titleLabel
                .padding(.init(x: 18, y: 0)),
            BEStackViewSpacing(4),
            subtitleLabel
                .padding(.init(x: 18, y: 0)),
            BEStackViewSpacing(18),
            createTransactionStatusView(),
            BEStackViewSpacing(18),
            transactionIDStackView,
            BEStackViewSpacing(36),
            buttonStackView
                .padding(.init(x: 18, y: 0))
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
        
        primaryButton.setTitle(text: L10n.done)
        primaryButton.setImage(image: nil)
        primaryButton.onTap(self, action: #selector(doneButtonDidTouch))
        secondaryButton.setTitle(text: L10n.makeAnotherTransaction)
        secondaryButton.onTap(self, action: #selector(makeAnotherTransaction))
    }
    
    private func layoutConfirmedTransaction() {
        self.titleLabel.text = L10n.success
        self.subtitleLabel.text = L10n.transactionHasBeenConfirmed
        self.transactionStatusImageView.image = .transactionSuccess
        
        primaryButton.setTitle(text: viewModel.transactionType.isSwap ? L10n.showSwapDetails: L10n.showTransactionDetails)
        primaryButton.setImage(image: .info)
        primaryButton.onTap(self, action: #selector(doneButtonDidTouch))
        
        secondaryButton.setTitle(text: L10n.makeAnotherTransaction)
        secondaryButton.onTap(self, action: #selector(makeAnotherTransaction))
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
        }
        
        primaryButton.setTitle(text: L10n.tryAgain)
        primaryButton.setImage(image: nil)
        primaryButton.onTap(self, action: #selector(tryAgain))
        
        secondaryButton.setTitle(text: L10n.cancel)
        secondaryButton.onTap(self, action: #selector(cancel))
    }
    
    private func layoutWithSpecificError(
        image: UIImage
    ) {
        stackView.arrangedSubviews.forEach {$0.removeFromSuperview()}
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
        
        primaryButton.setTitle(text: L10n.ok)
        primaryButton.setImage(image: nil)
        primaryButton.onTap(self, action: #selector(cancel))
        
        secondaryButton.setTitle(text: L10n.makeAnotherTransaction)
        secondaryButton.onTap(self, action: #selector(makeAnotherTransaction))
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
