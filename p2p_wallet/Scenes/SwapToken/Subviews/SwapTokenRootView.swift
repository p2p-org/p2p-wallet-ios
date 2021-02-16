//
//  SwapTokenRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/02/2021.
//

import UIKit
import RxSwift
import Action
import RxBiBinding

class SwapTokenRootView: ScrollableVStackRootView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: SwapTokenViewModel
    let disposeBag = DisposeBag()
    
    // MARK: - Subviews
    lazy var availableSourceBalanceLabel = UILabel(text: "Available", weight: .bold, textColor: .h5887ff)
        .onTap(viewModel, action: #selector(SwapTokenViewModel.useAllBalance))
    lazy var destinationBalanceLabel = UILabel(weight: .bold, textColor: .textSecondary)
    lazy var sourceWalletView = SwapTokenWalletView(forAutoLayout: ())
    lazy var destinationWalletView = SwapTokenWalletView(forAutoLayout: ())
    
    lazy var exchangeRateLabel = UILabel(text: nil)
    lazy var exchangeRateReverseButton = UIImageView(width: 18, height: 18, image: .walletSwap, tintColor: .h8b94a9)
        .onTap(viewModel, action: #selector(SwapTokenViewModel.reverseExchangeRate))
    
    lazy var reverseButton = UIImageView(width: 44, height: 44, cornerRadius: 12, image: .reverseButton)
        .onTap(viewModel, action: #selector(SwapTokenViewModel.swapSourceAndDestination))
    
    lazy var minimumReceiveLabel = UILabel(text: nil)
    lazy var feeLabel = UILabel(text: nil)
    lazy var slippageLabel = UILabel(text: nil)
    
    lazy var errorLabel = UILabel(textSize: 12, weight: .medium, textColor: .red, numberOfLines: 0, textAlignment: .center)
    
    lazy var swapButton = WLButton.stepButton(type: .blue, label: L10n.swapNow)
        .onTap(viewModel, action: #selector(SwapTokenViewModel.swap))
    
    // MARK: - Initializers
    init(viewModel: SwapTokenViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }
    
    // MARK: - Methods
    override func commonInit() {
        super.commonInit()
        backgroundColor = .vcBackground
        layout()
        bind()
        
        // setup actions
        sourceWalletView.chooseTokenAction = CocoaAction {
            self.viewModel.chooseSourceWallet()
            return .just(())
        }
        
        destinationWalletView.chooseTokenAction = CocoaAction {
            self.viewModel.chooseDestinationWallet()
            return .just(())
        }
        
        // set up textfields
        sourceWalletView.amountTextField.delegate = self
        
        // disable editing in toWallet text field
        destinationWalletView.amountTextField.isUserInteractionEnabled = false
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
    }
}

// MARK: - TextField delegate
extension SwapTokenRootView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let textField = textField as? TokenAmountTextField {
            return textField.shouldChangeCharactersInRange(range, replacementString: string)
        }
        return true
    }
}

// MARK: - Layout
private extension SwapTokenRootView {
    func layout() {
        stackView.spacing = 30
        
        stackView.addArrangedSubviews([
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.from, weight: .bold),
                availableSourceBalanceLabel
            ]),
            sourceWalletView,
            BEStackViewSpacing(8),
            swapSourceAndDestinationView(),
            BEStackViewSpacing(16),
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.to, weight: .bold),
                destinationBalanceLabel
            ]),
            destinationWalletView,
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.price + ": "),
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
            .onTap(viewModel, action: #selector(SwapTokenViewModel.chooseSlippage)),
            errorLabel,
            swapButton
        ])
    }
    
    func swapSourceAndDestinationView() -> UIView {
        let view = UIView(forAutoLayout: ())
        let separator = UIView.separator(height: 1, color: .separator)
        view.addSubview(separator)
        separator.autoPinEdge(toSuperviewEdge: .leading)
        separator.autoPinEdge(toSuperviewEdge: .trailing)
        separator.autoAlignAxis(toSuperviewAxis: .horizontal)
        
        view.addSubview(reverseButton)
        reverseButton.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .leading)
        
        return view
    }
}

// MARK: - Binding
private extension SwapTokenRootView {
    func bind() {
        // pool validation
        viewModel.pools.observable
            .subscribe(onNext: {[weak self] state in
                self?.removeErrorView()
                self?.hideHud()
                self?.stackView.isHidden = true
                switch state {
                case .initializing, .loading:
                    self?.showIndetermineHudWithMessage(L10n.loading)
                case .loaded:
                    self?.stackView.isHidden = false
                    if self?.viewModel.pools.value?.isEmpty == true {
                        self?.showErrorView(title: L10n.swappingIsCurrentlyUnavailable, description: L10n.swappingPoolsNotFound + "\n" + L10n.pleaseTryAgainLater)
                    }
                case .error(let error):
                    self?.showErrorView(error: error)
                }
            })
            .disposed(by: disposeBag)
        
        // available source balance label
        viewModel.sourceWallet
            .map {$0?.amount ?? 0}
            .map {$0.toString(maximumFractionDigits: 9)}
            .map {"\(L10n.available): \($0) \(self.viewModel.sourceWallet.value?.symbol ?? "")"}
            .asDriver(onErrorJustReturn: "")
            .drive(availableSourceBalanceLabel.rx.text)
            .disposed(by: disposeBag)
        
        // source wallet view
        viewModel.sourceWallet
            .subscribe(onNext: { [weak self] wallet in
                self?.sourceWalletView.setUp(wallet: wallet)
            })
            .disposed(by: disposeBag)
        
        // destination wallet view
        viewModel.destinationWallet
            .subscribe(onNext: { [weak self] wallet in
                self?.destinationWalletView.setUp(wallet: wallet)
                if let amount = wallet?.amount?.toString(maximumFractionDigits: 9) {
                    self?.destinationBalanceLabel.text = L10n.balance + ": " + amount + " " + "\(wallet?.symbol ?? "")"
                } else {
                    self?.destinationBalanceLabel.text = nil
                }
            })
            .disposed(by: disposeBag)
        
        // text fields
        (sourceWalletView.amountTextField.rx.text <-> viewModel.sourceAmountInput)
            .disposed(by: disposeBag)
        
        (destinationWalletView.amountTextField.rx.text <-> viewModel.destinationAmountInput)
            .disposed(by: disposeBag)
        
        // equity value labels
        Observable.combineLatest(
            viewModel.sourceAmountInput,
            viewModel.sourceWallet
        )
            .map {sourceAmountInput, sourceWallet in
                if let sourceWallet = sourceWallet {
                    let value = sourceAmountInput.toDouble() * sourceWallet.priceInUSD
                    return "≈ \(value.toString(maximumFractionDigits: 9)) $"
                } else {
                    return L10n.selectCurrency
                }
            }
            .asDriver(onErrorJustReturn: "")
            .drive(self.sourceWalletView.equityValueLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.destinationWallet
            .map {destinationWallet -> String? in
                if destinationWallet != nil {
                    return nil
                } else {
                    return L10n.selectCurrency
                }
            }
            .asDriver(onErrorJustReturn: nil)
            .drive(self.destinationWalletView.equityValueLabel.rx.text)
            .disposed(by: disposeBag)
        
        // exchange rate label
        Observable.combineLatest(
            viewModel.currentPool,
            viewModel.sourceWallet,
            viewModel.sourceAmountInput,
            viewModel.destinationWallet,
            viewModel.isReversedExchangeRate
        )
            .map {pool, sourceWallet, sourceAmount, destinationWallet, isReversed -> String? in
                let amountIn = sourceAmount.toDouble() ?? 1
                guard let pool = pool,
                      var fromSymbol = sourceWallet?.symbol,
                      var toSymbol = destinationWallet?.symbol,
                      var fromDecimals = sourceWallet?.decimals,
                      var toDecimals = destinationWallet?.decimals
                else {
                    return nil
                }
                let amountOut = pool.estimatedAmount(forInputAmount: amountIn.toLamport(decimals: fromDecimals))?.convertToBalance(decimals: toDecimals)
                
                var rate = amountOut / amountIn
                if isReversed {
                    rate = amountIn / amountOut
                    
                    // swap symbol
                    swap(&fromSymbol, &toSymbol)
                    
                    // swap decimals
                    swap(&fromDecimals, &toDecimals)
                }
                
                return rate.toString(maximumFractionDigits: toDecimals) + " "
                    + toSymbol + " "
                    + L10n.per + " "
                    + fromSymbol
            }
            .asDriver(onErrorJustReturn: nil)
            .drive(exchangeRateLabel.rx.text)
            .disposed(by: disposeBag)
        
        // minimum receive
        Observable.combineLatest(
            viewModel.minimumReceiveAmount,
            viewModel.destinationWallet
        )
            .map {minReceiveAmount, wallet -> String? in
                guard let symbol = wallet?.symbol else {return nil}
                return minReceiveAmount?.toString(maximumFractionDigits: 9) + " " + symbol
            }
            .asDriver(onErrorJustReturn: nil)
            .drive(minimumReceiveLabel.rx.text)
            .disposed(by: disposeBag)
        
        // fee
        Observable.combineLatest(
            viewModel.currentPool,
            viewModel.sourceWallet,
            viewModel.sourceAmountInput
        )
            .map {pool, sourceWallet, amountInput -> String? in
                guard let pool = pool,
                      let decimals = sourceWallet?.decimals,
                      let lamports = amountInput.toDouble()?.toLamport(decimals: decimals),
                      let amount = pool.fee(forInputAmount: lamports)
                else {return nil}
                
                return amount.toString(maximumFractionDigits: 5) + " " + "SOL"
            }
            .asDriver(onErrorJustReturn: nil)
            .drive(feeLabel.rx.text)
            .disposed(by: disposeBag)
        
        // slippage
        viewModel.slippage
            .subscribe(onNext: {slippage in
                if !self.viewModel.isSlippageValid(slippage: slippage) {
                    self.slippageLabel.attributedText = NSMutableAttributedString()
                        .text((slippage * 100).toString() + " %", color: .red)
                        .text(" ")
                        .text("(\(L10n.max). 20%)", color: .textSecondary)
                } else {
                    self.slippageLabel.text = (slippage * 100).toString() + " %"
                }
            })
            .disposed(by: disposeBag)
        
        // error
        viewModel.errorSubject
            .asDriver()
            .drive(errorLabel.rx.text)
            .disposed(by: disposeBag)
        
        let hasError = viewModel.errorSubject.map {$0 != nil}
            .asDriver(onErrorJustReturn: false)
        
        hasError.drive(minimumReceiveLabel.superview!.rx.isHidden)
            .disposed(by: disposeBag)
            
        hasError.drive(feeLabel.superview!.rx.isHidden)
            .disposed(by: disposeBag)
        
        // swap button
        Observable.combineLatest(
            viewModel.currentPool,
            viewModel.sourceAmountInput,
            viewModel.errorSubject.map {$0 == nil}
        )
            .map {$0 != nil && $1.toDouble() > 0 && $2}
            .asDriver(onErrorJustReturn: false)
            .drive(swapButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
}
