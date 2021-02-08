//
//  SwapTokenVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2020.
//

import Foundation
import RxSwift
import RxCocoa
import Action

class SwapTokenVC: WLModalWrapperVC {
    override var padding: UIEdgeInsets {super.padding.modifying(dLeft: .defaultPadding, dRight: .defaultPadding)}
    
    init(from fromWallet: Wallet? = nil, to toWallet: Wallet? = nil) {
        let vc = _SwapTokenVC(from: fromWallet, to: toWallet)
        super.init(wrapped: vc)
    }
    
    override func setUp() {
        super.setUp()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.addArrangedSubviews([
            UIImageView(width: 24, height: 24, image: .walletSwap, tintColor: .white)
                .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12),
            UILabel(text: L10n.swap, textSize: 17, weight: .semibold),
            UIImageView(width: 36, height: 36, image: .slippageSettings, tintColor: .a3a5ba)
                .onTap(self, action: #selector(buttonSlippageSettingsDidTouch))
        ])
        
        let separator = UIView.separator(height: 1, color: .separator)
        containerView.addSubview(separator)
        separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
    }
    
    @objc func buttonSlippageSettingsDidTouch() {
        (vc as! _SwapTokenVC).buttonChooseSlippageDidTouch()
    }
}

class _SwapTokenVC: BaseVStackVC {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .normal(backgroundColor: .vcBackground) }
    override var padding: UIEdgeInsets { UIEdgeInsets(top: .defaultPadding, left: 16, bottom: 0, right: 16) }
    
    let viewModel = SwapTokenVM()
    var isExchangeRateReversed = false
    
    lazy var availableSourceBalanceLabel = UILabel(text: "Available", textColor: .h5887ff)
        .onTap(self, action: #selector(buttonUseAllBalanceDidTouch))
    lazy var destinationBalanceLabel = UILabel(textColor: .textSecondary)
    lazy var sourceWalletView = SwapTokenItemView(forAutoLayout: ())
    lazy var destinationWalletView = SwapTokenItemView(forAutoLayout: ())
    
    lazy var exchangeRateLabel = UILabel(text: nil)
    lazy var exchangeRateReverseButton = UIImageView(width: 18, height: 18, image: .walletSwap, tintColor: .h8b94a9)
        .onTap(self, action: #selector(buttonExchangeRateReverseDidTouch))
    
    lazy var reverseButton = UIImageView(width: 44, height: 44, cornerRadius: 12, image: .reverseButton)
        .onTap(self, action: #selector(buttonReverseDidTouch))
    
    lazy var minimumReceiveLabel = UILabel(text: nil)
    lazy var feeLabel = UILabel(text: nil)
    lazy var slippageLabel = UILabel(text: nil)
    
    lazy var errorLabel = UILabel(textSize: 12, weight: .medium, textColor: .red, numberOfLines: 0, textAlignment: .center)
    
    lazy var swapButton = WLButton.stepButton(type: .blue, label: L10n.swapNow)
        .onTap(self, action: #selector(buttonSwapDidTouch))
    
    init(from fromWallet: Wallet? = nil, to toWallet: Wallet? = nil) {
        super.init()
        defer {
            self.viewModel.sourceWallet.accept(fromWallet ?? viewModel.wallets.first(where: {$0.symbol == "SOL"}))
            self.viewModel.destinationWallet.accept(toWallet)
        }
    }
    
    override func setUp() {
        super.setUp()
        // Set up ui
        view.backgroundColor = .vcBackground
        title = L10n.swap
        
        // set up stackView
        stackView.spacing = 30
        stackView.constraintToSuperviewWithAttribute(.leading)?.constant = 16
        stackView.constraintToSuperviewWithAttribute(.trailing)?.constant = -16
        stackView.constraintToSuperviewWithAttribute(.bottom)?.constant = -20
        
        let reverseView: UIView = {
            let view = UIView(forAutoLayout: ())
            let separator = UIView.separator(height: 1, color: .separator)
            view.addSubview(separator)
            separator.autoPinEdge(toSuperviewEdge: .leading)
            separator.autoPinEdge(toSuperviewEdge: .trailing)
            separator.autoAlignAxis(toSuperviewAxis: .horizontal)
            
            view.addSubview(reverseButton)
            reverseButton.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .leading)
            
            return view
        }()
        
        stackView.addArrangedSubviews([
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.from),
                availableSourceBalanceLabel
            ]),
            sourceWalletView,
            BEStackViewSpacing(8),
            reverseView,
            BEStackViewSpacing(16),
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.to),
                destinationBalanceLabel
            ]),
            destinationWalletView,
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.exchangeRate + ": "),
                exchangeRateLabel
                    .withContentHuggingPriority(.required, for: .horizontal),
                exchangeRateReverseButton
            ])
                .padding(.init(all: 8), backgroundColor: .f6f6f8, cornerRadius: 12),
            UIView.separator(height: 1, color: .separator),
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.minimumReceive + ": "),
                minimumReceiveLabel
            ]),
            BEStackViewSpacing(16),
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.fee + ": "),
                feeLabel
            ]),
            BEStackViewSpacing(16),
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.slippage + ": "),
                slippageLabel
            ])
                .onTap(self, action: #selector(buttonChooseSlippageDidTouch)),
            errorLabel,
            swapButton
        ])
        
        // setup actions
        sourceWalletView.chooseTokenAction = CocoaAction {
            let vc = ChooseWalletVC()
            vc.completion = {wallet in
                let wallet = self.viewModel.wallets.first(where: {$0.pubkey == wallet.pubkey})
                self.viewModel.sourceWallet.accept(wallet)
                self.sourceWalletView.amountTextField.becomeFirstResponder()
                vc.back()
            }
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
        
        destinationWalletView.chooseTokenAction = CocoaAction {
            let vc = ChooseWalletVC(customFilter: {_ in true})
            vc.completion = {wallet in
                let wallet = self.viewModel.wallets.first(where: {$0.pubkey == wallet.pubkey})
                self.viewModel.destinationWallet.accept(wallet)
                vc.back()
            }
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
        
        // set up textfields
        sourceWalletView.amountTextField.delegate = self
        sourceWalletView.amountTextField.becomeFirstResponder()
        
        // disable editing in toWallet text field
        destinationWalletView.amountTextField.isUserInteractionEnabled = false
        destinationWalletView.equityValueLabel.isHidden = true
    }
    
    override func bind() {
        super.bind()
        // pool validation
        viewModel.poolsVM
            .state
            .subscribe(onNext: {[weak self] state in
                self?.removeErrorView()
                self?.hideHud()
                switch state {
                case .initializing, .loading:
                    self?.showIndetermineHudWithMessage(L10n.loading)
                case .loaded(let pools):
                    if pools.isEmpty {
                        self?.showErrorView(title: L10n.swappingIsCurrentlyUnavailable, description: L10n.swappingPoolsNotFound + "\n" + L10n.pleaseTryAgainLater)
                    }
                case .error(let error):
                    self?.showErrorView(title: L10n.swappingIsCurrentlyUnavailable, description: error.localizedDescription + "\n" + L10n.pleaseTryAgainLater)
                }
            })
            .disposed(by: disposeBag)
        
        // bind amount
        sourceWalletView.amountTextField.rx.text.orEmpty
            .map {$0.double}
            .bind(to: viewModel.amount)
            .disposed(by: disposeBag)
        
        // source/destination wallet
        Observable.combineLatest(
            viewModel.poolsVM.dataDidChange,
            viewModel.sourceWallet,
            viewModel.destinationWallet,
            viewModel.amount,
            viewModel.slippage
        )
            .subscribe(onNext: { (_, sourceWallet, destinationWallet, amount, slippage) in
                // configure source wallet
                self.sourceWalletView.setUp(wallet: sourceWallet)
                
                if let wallet = sourceWallet {
                    self.availableSourceBalanceLabel.text = "\(L10n.available): \(wallet.amount.toString(maximumFractionDigits: 9)) \(wallet.symbol)"
                } else {
                    self.availableSourceBalanceLabel.text = nil
                }
                
                // configure destinationWallet
                self.destinationWalletView.setUp(wallet: destinationWallet)
                
                if let wallet = destinationWallet {
                    self.destinationBalanceLabel.text = "\(L10n.balance): \(wallet.amount.toString(maximumFractionDigits: 9)) \(wallet.symbol)"
                } else {
                    self.destinationBalanceLabel.text = nil
                }
                
                // pool validation
                var errorText: String?
                self.sourceWalletView.amountTextField.isUserInteractionEnabled = true
                self.availableSourceBalanceLabel.isUserInteractionEnabled = true
                self.exchangeRateLabel.text = nil
                
                if let pool = self.viewModel.currentPool {
                    // supported
                    if self.sourceWalletView.amountTextField.text?.isEmpty == false,
                       let estimatedAmount = self.viewModel.estimatedAmount,
                       let minimumReceiveAmount = self.viewModel.minimumReceiveAmount,
                       let sourceDecimals = sourceWallet?.decimals,
                       let destinationDecimals = destinationWallet?.decimals,
                       let inputAmount = amount?.toLamport(decimals: sourceDecimals),
                       let fee = pool.fee(forInputAmount: inputAmount)
                    {
                        self.destinationWalletView.amountTextField.text = estimatedAmount.toString(maximumFractionDigits: destinationDecimals)
                        self.minimumReceiveLabel.text = "\(minimumReceiveAmount.toString(maximumFractionDigits: destinationDecimals)) \(destinationWallet!.symbol)"
                        
                        self.feeLabel.text = "\(fee.toString(maximumFractionDigits: 5)) SOL"
                        self.setUpExchangeRateLabel()
                    } else {
                        self.destinationWalletView.amountTextField.text = nil
                    }
                } else {
                    // unsupported
                    self.destinationWalletView.amountTextField.text = nil
                    
                    if let sourceWallet = sourceWallet,
                       let destinationWallet = destinationWallet,
                       !self.viewModel.poolsVM.data.isEmpty
                    {
                        if sourceWallet.symbol == destinationWallet.symbol {
                            errorText = L10n.YouCanNotSwapToItself.pleaseChooseAnotherToken(sourceWallet.symbol)
                        } else {
                            errorText = L10n.swappingFromToIsCurrentlyUnsupported(self.viewModel.sourceWallet.value!.symbol, self.viewModel.destinationWallet.value!.symbol)
                        }
                        
                        self.sourceWalletView.amountTextField.resignFirstResponder()
                        self.sourceWalletView.amountTextField.isUserInteractionEnabled = false
                        self.availableSourceBalanceLabel.isUserInteractionEnabled = false
                    }
                }
                
                // amount
                if amount > sourceWallet?.amount {
                    errorText = L10n.insufficientFunds
                }
                
                // slippage
                if slippage > 20 || slippage < 0 {
                    errorText = L10n.slippageIsnTValid
                    self.slippageLabel.attributedText = NSMutableAttributedString()
                        .text(slippage.toString() + " %", color: .red)
                        .text(" ")
                        .text("(\(L10n.max). 20%)", color: .textSecondary)
                } else {
                    self.slippageLabel.text = slippage.toString() + " %"
                }
                
                // handle error
                self.errorLabel.text = errorText
                
                let hasError = errorText != nil
                self.minimumReceiveLabel.superview?.isHidden = hasError
                self.feeLabel.superview?.isHidden = hasError
                self.errorLabel.isHidden = !hasError
                
                let shouldEnableSwapButton = !self.viewModel.poolsVM.data.isEmpty && !hasError && destinationWallet != nil && amount > 0
                self.swapButton.isEnabled = shouldEnableSwapButton
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    @objc func buttonUseAllBalanceDidTouch() {
        guard let token = viewModel.sourceWallet.value?.amount else {return}
        sourceWalletView.amountTextField.text = token.toString(maximumFractionDigits: 9)
        sourceWalletView.amountTextField.sendActions(for: .valueChanged)
    }
    
    @objc func buttonReverseDidTouch() {
        let tempWallet = viewModel.sourceWallet.value
        viewModel.sourceWallet.accept(viewModel.destinationWallet.value)
        viewModel.destinationWallet.accept(tempWallet)
    }
    
    @objc func buttonExchangeRateReverseDidTouch() {
        isExchangeRateReversed.toggle()
        setUpExchangeRateLabel()
    }
    
    @objc func buttonChooseSlippageDidTouch() {
        let vc = SwapSlippageSettingsVC(slippage: Defaults.slippage)
        vc.completion = {slippage in
            Defaults.slippage = slippage
            self.viewModel.slippage.accept(slippage)
        }
        present(vc, animated: true, completion: nil)
    }
    
    @objc func buttonSwapDidTouch() {
        let transactionVC = presentProcessTransactionVC()
        viewModel.swap()
            .subscribe { (signature) in
                transactionVC.signature = signature
                transactionVC.viewInExplorerButton.rx.action = CocoaAction {
                    transactionVC.dismiss(animated: true) {
                        let nc = self.navigationController
                        self.back()
                        nc?.showWebsite(url: "https://explorer.solana.com/tx/" + signature)
                    }
                    
                    return .just(())
                }
                transactionVC.goBackToWalletButton.rx.action = CocoaAction {
                    transactionVC.dismiss(animated: true) {
                        self.back()
                    }
                    return .just(())
                }
                
                let transaction = Transaction(
                    signatureInfo: .init(signature: signature),
                    type: .send,
                    amount: -self.viewModel.amount.value!,
                    symbol: self.viewModel.sourceWallet.value!.symbol,
                    status: .processing
                )
                TransactionsManager.shared.process(transaction)
                
                let transaction2 = Transaction(
                    signatureInfo: .init(signature: signature),
                    type: .send,
                    amount: +self.viewModel.estimatedAmount!,
                    symbol: self.viewModel.destinationWallet.value!.symbol,
                    status: .processing
                )
                TransactionsManager.shared.process(transaction2)
            } onError: { (error) in
                transactionVC.dismiss(animated: true) {
                    self.showError(error)
                }
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
    func setUpExchangeRateLabel() {
        guard let amountIn = viewModel.amount.value,
              let amountOut = viewModel.estimatedAmount,
              var fromSymbol = viewModel.sourceWallet.value?.symbol,
              var toSymbol = viewModel.destinationWallet.value?.symbol,
              var fromDecimals = viewModel.sourceWallet.value?.decimals,
              var toDecimals = viewModel.destinationWallet.value?.decimals
        else {
            exchangeRateLabel.text = nil
            return
        }
        
        var rate = amountOut / amountIn
        if isExchangeRateReversed {
            rate = amountIn / amountOut
            
            // swap symbol
            let tempSymbol = fromSymbol
            fromSymbol = toSymbol
            toSymbol = tempSymbol
            
            // swap decimals
            let tempDecimals = fromDecimals
            fromDecimals = toDecimals
            toDecimals = tempDecimals
        }
        
        exchangeRateLabel.text = rate.toString(maximumFractionDigits: toDecimals) + " "
            + toSymbol + " "
            + L10n.per + " "
            + fromSymbol
    }
}

extension _SwapTokenVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let textField = textField as? TokenAmountTextField {
            return textField.shouldChangeCharactersInRange(range, replacementString: string)
        }
        return true
    }
}
