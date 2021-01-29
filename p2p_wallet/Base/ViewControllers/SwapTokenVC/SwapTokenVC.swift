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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        ])
        
        let separator = UIView.separator(height: 1, color: .separator)
        containerView.addSubview(separator)
        separator.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
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
        super.init(nibName: nil, bundle: nil)
        defer {
            self.viewModel.sourceWallet.accept(fromWallet ?? viewModel.wallets.first(where: {$0.symbol == "SOL"}))
            self.viewModel.destinationWallet.accept(toWallet)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            ]),
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
            let vc = ChooseWalletVC()
            vc.customFilter = {_ in true}
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
            viewModel.amount
        )
            .subscribe(onNext: { (_, sourceWallet, destinationWallet, _) in
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
                self.exchangeRateLabel.text = nil
                
                if let pool = self.viewModel.currentPool {
                    // supported
                    if self.sourceWalletView.amountTextField.text?.isEmpty == false,
                       let estimatedAmount = self.viewModel.estimatedAmount,
                       let minimumReceiveAmount = self.viewModel.minimumReceiveAmount,
                       let decimals = self.viewModel.destinationWallet.value?.decimals
                    {
                        self.destinationWalletView.amountTextField.text = estimatedAmount.toString(maximumFractionDigits: decimals)
                        self.minimumReceiveLabel.text = "\(minimumReceiveAmount.toString(maximumFractionDigits: decimals)) \(destinationWallet!.symbol)"
                        self.feeLabel.text = pool.fee.toString(maximumFractionDigits: 9)
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
                    }
                }
                
                // handle error
                self.errorLabel.text = errorText
                
                let hasError = errorText != nil
                self.minimumReceiveLabel.superview?.isHidden = hasError
                self.feeLabel.superview?.isHidden = hasError
                self.slippageLabel.superview?.isHidden = hasError
                self.errorLabel.isHidden = !hasError
            })
            .disposed(by: disposeBag)
        
        viewModel.slippage
            .map {$0.toString() + " %"}
            .asDriver(onErrorJustReturn: "")
            .drive(slippageLabel.rx.text)
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
    
    @objc func buttonSwapDidTouch() {
        
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
