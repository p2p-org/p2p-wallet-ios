//
//  ProcessTransaction.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 02/06/2021.
//

import UIKit
import RxSwift
import RxCocoa
import BEPureLayout

extension ProcessTransaction {
    class RootView: BEView {
        // MARK: - Constants
        private let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private let viewModel: ProcessTransactionViewModelType
        
        // MARK: - Subviews
        private lazy var titleLabel = UILabel(textSize: 20, weight: .semibold, numberOfLines: 0, textAlignment: .center)
        private lazy var subtitleLabel = UILabel(textColor: .textSecondary, numberOfLines: 1, textAlignment: .center)
        private lazy var transactionStatusView = TransactionStatusView(forAutoLayout: ())
        
        private lazy var transactionIDLabel = UILabel(textSize: 15, textAlignment: .right)
        private lazy var errorLabel = UILabel(textSize: 15, weight: .medium, numberOfLines: 0, textAlignment: .center)
        
        // MARK: - Substackviews
        private lazy var transactionIDStackView = UIStackView(axis: .horizontal, spacing: 0, alignment: .top, distribution: .fill) {
            UILabel(text: L10n.transactionID, textSize: 15, textColor: .textSecondary)
            BEStackViewSpacing(4)
            UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                UIStackView(axis: .horizontal, spacing: 4, alignment: .center, distribution: .fill) {
                    transactionIDLabel
                    UIImageView(width: 16, height: 16, image: .transactionShowInExplorer, tintColor: .textSecondary)
                }
                
                UILabel(text: L10n.tapToViewInExplorer, textSize: 15, textColor: .textSecondary, numberOfLines: 0, textAlignment: .right)
                    
            }
                .onTap(self, action: #selector(showExplorer))
        }
            .padding(.init(x: 20, y: 0))
        private lazy var buttonStackView = UIStackView(axis: .vertical, spacing: 10, alignment: .fill, distribution: .fill) {
            primaryButton
            secondaryButton
        }
        private lazy var primaryButton = WLStepButton.main(image: .info, text: L10n.showTransactionDetails)
        private lazy var secondaryButton = WLStepButton.sub(text: L10n.makeAnotherTransaction)
        
        // MARK: - Initializers
        init(viewModel: ProcessTransactionViewModelType) {
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
            let stackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)
            addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 0, y: 18))
            stackView.spacing = 0
            
            stackView.addArrangedSubviews {
                titleLabel
                    .padding(.init(x: 18, y: 0))
                BEStackViewSpacing(4)
                subtitleLabel
                    .padding(.init(x: 18, y: 0))
                BEStackViewSpacing(18)
                transactionStatusView
                BEStackViewSpacing(18)
                transactionIDStackView
                BEStackViewSpacing(36)
                errorLabel
                BEStackViewSpacing(36)
                buttonStackView
                    .padding(.init(x: 18, y: 0))
            }
            
            transactionIDStackView.isHidden = true
            errorLabel.isHidden = true
        }
        
        private func bind() {
            switch viewModel.transactionType {
            case .closeAccount:
                viewModel.fetchReimbursedAmountForClosingTransaction()
                    .subscribe(onSuccess: {[weak self] _ in
                        self?.bindLayout()
                    })
                    .disposed(by: disposeBag)
            default:
                bindLayout()
            }
        }
        
        private func bindLayout() {
            viewModel.transactionDriver
                .drive(onNext: { [weak self] transaction in
                    self?.setUp(transaction: transaction)
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc private func showExplorer() {
            viewModel.showExplorer()
        }
        
        @objc func doneButtonDidTouch() {
            viewModel.markAsDone()
        }
        
        @objc func tryAgain() {
            viewModel.tryAgain()
        }
        
        @objc func cancel() {
            viewModel.cancel()
        }
        
        @objc func makeAnotherTransaction() {
            fatalError()
        }
    }
}

private extension ProcessTransaction {
    final class TransactionStatusView: BEView {
        private lazy var transactionStatusImageView = UIImageView(width: 44, height: 44, image: .transactionProcessing)
        private lazy var transactionIndicatorView: TransactionIndicatorView = {
            let indicatorView = TransactionIndicatorView(height: 1, backgroundColor: .separator)
            indicatorView.tintColor = .h5887ff
            return indicatorView
        }()
        
        override func commonInit() {
            super.commonInit()
            addSubview(transactionIndicatorView)
            transactionIndicatorView.autoPinEdge(toSuperviewEdge: .leading)
            transactionIndicatorView.autoPinEdge(toSuperviewEdge: .trailing)
            transactionIndicatorView.autoAlignAxis(toSuperviewAxis: .horizontal)
            addSubview(transactionStatusImageView)
            transactionStatusImageView.autoPinEdge(toSuperviewEdge: .top)
            transactionStatusImageView.autoPinEdge(toSuperviewEdge: .bottom)
            transactionStatusImageView.autoAlignAxis(toSuperviewAxis: .vertical)
        }
        
        fileprivate func setImage(_ image: UIImage) {
            transactionStatusImageView.image = image
        }
    }
}

// MARK: - Setup
private extension ProcessTransaction.RootView {
    func setUp(transaction: SolanaSDK.ParsedTransaction) {
        transactionIDStackView.isHidden = false
        errorLabel.isHidden = true
        
        // title, subtitle, image, button
        switch transaction.status {
        case .requesting, .processing:
            setUpWithProcessingTransaction()
        case .confirmed:
            setUpWithConfirmedTransaction()
        case .error(let error):
            setUpWithTransactionError(error ?? L10n.somethingWentWrong)
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
    
    func setUpWithProcessingTransaction() {
        switch viewModel.transactionType {
        case .send, .closeAccount:
            titleLabel.text = L10n.sending + "..."
            subtitleLabel.text = L10n.transactionProcessing
        case .orcaSwap, .swap:
            titleLabel.text = L10n.swapping + "..."
            subtitleLabel.text = L10n.transactionProcessing
        }
        
        transactionStatusView.setImage(.transactionProcessing)
        transactionIDStackView.isHidden = true
        
        primaryButton.setTitle(text: L10n.done)
        primaryButton.setImage(image: nil)
        primaryButton.onTap(self, action: #selector(doneButtonDidTouch))
        secondaryButton.setTitle(text: L10n.makeAnotherTransaction)
        secondaryButton.onTap(self, action: #selector(makeAnotherTransaction))
    }
    
    func setUpWithConfirmedTransaction() {
        titleLabel.text = L10n.success
        subtitleLabel.text = L10n.transactionHasBeenConfirmed
        
        transactionStatusView.setImage(.transactionSuccess)
        
        primaryButton.setTitle(text: viewModel.transactionType.isSwap ? L10n.showSwapDetails: L10n.showTransactionDetails)
        primaryButton.setImage(image: .info)
        primaryButton.onTap(self, action: #selector(doneButtonDidTouch))
        
        secondaryButton.setTitle(text: L10n.makeAnotherTransaction)
        secondaryButton.onTap(self, action: #selector(makeAnotherTransaction))
    }
    
    func setUpWithTransactionError(_ error: String) {
        errorLabel.isHidden = false
        
        let transactionType = viewModel.transactionType
        // specific errors
        
        // When trying to send a wrapped token to a new SOL wallet (which is not yet in the blockchain)
        if error == L10n.invalidAccountInfo ||
            error == L10n.couldNotRetrieveAccountInfo
        {
            setUpWithSpecificError(
                image: .transactionErrorInvalidAccountInfo
            )
            
            titleLabel.text = L10n.invalidAccountInfo
            subtitleLabel.text = L10n.CheckEnteredAccountInfoForSending.itShouldBeAccountInSolanaNetwork
            errorLabel.text =  L10n.CheckEnteredAccountInfoForSending.itShouldBeAccountInSolanaNetwork
        }
        
        // When trying to send a wrapped token to another wrapped token
        else if error == L10n.walletAddressIsNotValid {
            setUpWithSpecificError(
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
            errorLabel.text = L10n.itMustBeAnWalletAddress(symbol)
        }
        
        // When a user entered an incorrect recipient address
        else if error == L10n.wrongWalletAddress
        {
            setUpWithSpecificError(
                image: .transactionErrorWrongWallet
            )
            
            titleLabel.text = L10n.wrongWalletAddress
            subtitleLabel.text = L10n.checkEnterredWalletAddressAndTryAgain
            errorLabel.text = L10n.checkEnterredWalletAddressAndTryAgain
        }
        
        // When the user needs to correct the slippage value
        else if error == L10n.swapInstructionExceedsDesiredSlippageLimit
        {
            setUpWithSpecificError(
                image: .transactionErrorSlippageExceeded
            )
            
            titleLabel.text = L10n.slippageError
            subtitleLabel.text = L10n.SwapInstructionExceedsDesiredSlippageLimit.setAnotherSlippageAndTryAgain
            errorLabel.text = L10n.SwapInstructionExceedsDesiredSlippageLimit.setAnotherSlippageAndTryAgain
        }
        
        // System error
        else if [
            L10n.theFeeCalculationFailedDueToOverflowUnderflowOrUnexpected0,
            L10n.errorProcessingInstruction0CustomProgramError0x1,
            L10n.blockhashNotFound
        ]
            .contains(error)
        {
            setUpWithSpecificError(
                image: .transactionErrorSystem
            )
            
            titleLabel.text = L10n.systemError
            subtitleLabel.text = error
            errorLabel.text = error
        }
        
        // generic errors
        else {
            titleLabel.text = L10n.somethingWentWrong
            subtitleLabel.text = error
            errorLabel.text = error
            transactionStatusView.setImage(.transactionError)
            
            primaryButton.setTitle(text: L10n.tryAgain)
            primaryButton.setImage(image: nil)
            primaryButton.onTap(self, action: #selector(tryAgain))
            
            secondaryButton.setTitle(text: L10n.cancel)
            secondaryButton.onTap(self, action: #selector(cancel))
        }
    }
    
    func setUpWithSpecificError(
        image: UIImage
    ) {
        primaryButton.setTitle(text: L10n.ok)
        primaryButton.setImage(image: nil)
        primaryButton.onTap(self, action: #selector(cancel))
        
        secondaryButton.setTitle(text: L10n.makeAnotherTransaction)
        secondaryButton.onTap(self, action: #selector(makeAnotherTransaction))
    }
}
