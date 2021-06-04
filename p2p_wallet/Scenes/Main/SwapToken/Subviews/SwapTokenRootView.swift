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
    lazy var availableSourceBalanceLabel = UILabel(text: "Available", weight: .medium, textColor: .h5887ff)
        .onTap(viewModel, action: #selector(SwapTokenViewModel.useAllBalance))
    lazy var destinationBalanceLabel = UILabel(weight: .medium, textColor: .textSecondary)
    lazy var sourceWalletView = SwapToken.WalletView(forAutoLayout: ())
    lazy var destinationWalletView = SwapToken.WalletView(forAutoLayout: ())
    
    lazy var exchangeRateLabel = UILabel(text: nil)
    lazy var exchangeRateReverseButton = UIImageView(width: 18, height: 18, image: .walletSwap, tintColor: .h8b94a9)
        .onTap(viewModel, action: #selector(SwapTokenViewModel.reverseExchangeRate))
    
    lazy var reverseButton = UIImageView(width: 44, height: 44, cornerRadius: 12, image: .reverseButton)
        .onTap(viewModel, action: #selector(SwapTokenViewModel.swapSourceAndDestination))
    
    lazy var minimumReceiveLabel = UILabel(textColor: .textSecondary)
    lazy var feeLabel = UILabel(textColor: .textSecondary)
    lazy var slippageLabel = UILabel(textColor: .textSecondary)
    
    lazy var errorLabel = UILabel(textSize: 12, weight: .medium, textColor: .red, numberOfLines: 0, textAlignment: .center)
    
    lazy var swapButton = WLButton.stepButton(type: .blue, label: L10n.swapNow)
        .onTap(viewModel, action: #selector(SwapTokenViewModel.showSwapSceneAndSwap))
    
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
                UILabel(text: L10n.from, weight: .semibold),
                availableSourceBalanceLabel
            ]),
            sourceWalletView,
            BEStackViewSpacing(8),
            swapSourceAndDestinationView(),
            BEStackViewSpacing(8),
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.to, weight: .semibold),
                destinationBalanceLabel
            ]),
            destinationWalletView,
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.price + ": ", weight: .medium, textColor: .textSecondary),
                exchangeRateLabel
                    .withContentHuggingPriority(.required, for: .horizontal),
                exchangeRateReverseButton
            ])
                .padding(.init(all: 8), backgroundColor: .f6f6f8, cornerRadius: 12),
            UIView.separator(height: 1, color: .separator),
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.minimumReceive + ": ", textColor: .textSecondary),
                minimumReceiveLabel
            ]),
            BEStackViewSpacing(16),
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.fee + ": ", textColor: .textSecondary),
                feeLabel
            ]),
            BEStackViewSpacing(16),
            UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .equalSpacing, arrangedSubviews: [
                UILabel(text: L10n.slippage + ": ", textColor: .textSecondary),
                slippageLabel
            ])
            .onTap(viewModel, action: #selector(SwapTokenViewModel.chooseSlippage)),
            errorLabel,
            BEStackViewSpacing(16),
            swapButton,
            BEStackViewSpacing(12),
            UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill, arrangedSubviews: [
                UILabel(text: L10n.poweredBy, textSize: 13, textColor: .textSecondary, textAlignment: .center),
                UIImageView(width: 94, height: 24, image: .orcaLogo)
            ])
                .centeredHorizontallyView
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
                    self?.showIndetermineHud()
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
            .map {"\(L10n.available): \($0) \(self.viewModel.sourceWallet.value?.token.symbol ?? "")"}
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
                    self?.destinationBalanceLabel.text = L10n.balance + ": " + amount + " " + "\(wallet?.token.symbol ?? "")"
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
                    let value = sourceAmountInput.double * sourceWallet.priceInCurrentFiat
                    return "≈ \(value.toString(maximumFractionDigits: 9)) \(Defaults.fiat.symbol)"
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
        
        // pool
        let poolUnavailability = viewModel.currentPool.map {$0 == nil}
            .asDriver(onErrorJustReturn: false)
        
        // exchange rate label
        poolUnavailability
            .drive(exchangeRateLabel.superview!.superview!.rx.isHidden)
            .disposed(by: disposeBag)
        
        Observable.combineLatest(
            viewModel.currentPool,
            viewModel.sourceWallet,
            viewModel.sourceAmountInput,
            viewModel.destinationWallet,
            viewModel.isReversedExchangeRate
        )
            .map {pool, sourceWallet, sourceAmount, destinationWallet, isReversed -> String? in
                let amountIn: Double = {
                    guard let amount = sourceAmount.double else {return 1}
                    if amount <= 0 {return 1}
                    return amount
                }()
                
                guard let pool = pool,
                      var fromSymbol = sourceWallet?.token.symbol,
                      var toSymbol = destinationWallet?.token.symbol,
                      var fromDecimals = sourceWallet?.token.decimals,
                      var toDecimals = destinationWallet?.token.decimals
                else {
                    return nil
                }
                let amountOut = pool.estimatedAmount(forInputAmount: amountIn.toLamport(decimals: fromDecimals), includeFees: true)?.convertToBalance(decimals: toDecimals)
                
                var rate = amountOut / amountIn
                if isReversed {
                    rate = amountIn / amountOut
                    
                    // swap symbol
                    swap(&fromSymbol, &toSymbol)
                    
                    // swap decimals
                    swap(&fromDecimals, &toDecimals)
                }
                
                var string = rate.toString(maximumFractionDigits: Int(toDecimals))
                string += " "
                string += toSymbol
                string += " "
                string += L10n.per
                string += " "
                string += fromSymbol
                
                return string
            }
            .asDriver(onErrorJustReturn: nil)
            .drive(exchangeRateLabel.rx.text)
            .disposed(by: disposeBag)
        
        // minimum receive
        poolUnavailability
            .drive(minimumReceiveLabel.superview!.rx.isHidden)
            .disposed(by: disposeBag)
        
        Observable.combineLatest(
            viewModel.minimumReceiveAmount,
            viewModel.destinationWallet
        )
            .map {minReceiveAmount, wallet -> String? in
                guard let symbol = wallet?.token.symbol else {return nil}
                return minReceiveAmount?.toString(maximumFractionDigits: 9) + " " + symbol
            }
            .asDriver(onErrorJustReturn: nil)
            .drive(minimumReceiveLabel.rx.text)
            .disposed(by: disposeBag)
        
        // fee
        poolUnavailability
            .drive(feeLabel.superview!.rx.isHidden)
            .disposed(by: disposeBag)
        
        Observable.combineLatest(
            viewModel.currentPool,
            viewModel.sourceWallet,
            viewModel.sourceAmountInput,
            viewModel.destinationWallet
        )
            .map {pool, _, amountInput, destinationWallet -> String? in
                guard let pool = pool,
                      let amount = amountInput.double,
                      let amount = pool.fee(forInputAmount: amount)
                else {return nil}
                
                return amount.toString(maximumFractionDigits: 5) + " " + destinationWallet?.token.symbol
            }
            .asDriver(onErrorJustReturn: nil)
            .drive(feeLabel.rx.text)
            .disposed(by: disposeBag)
        
        // slippage
        poolUnavailability
            .drive(slippageLabel.superview!.rx.isHidden)
            .disposed(by: disposeBag)
        
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
        
        viewModel.errorSubject
            .map {$0 == nil || $0 == L10n.insufficientFunds || $0 == L10n.amountIsNotValid}
            .asDriver(onErrorJustReturn: true)
            .drive(errorLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.errorSubject
            .map {$0 == L10n.insufficientFunds || $0 == L10n.amountIsNotValid}
            .map {$0 ? UIColor.alert: UIColor.h5887ff}
            .asDriver(onErrorJustReturn: .h5887ff)
            .drive(availableSourceBalanceLabel.rx.textColor)
            .disposed(by: disposeBag)
        
        // swap button
        Observable.combineLatest(
            viewModel.currentPool,
            viewModel.sourceAmountInput,
            viewModel.errorSubject.map {$0 == nil}
        )
            .map {$0 != nil && $1.double > 0 && $2}
            .asDriver(onErrorJustReturn: false)
            .drive(swapButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        // loading
        viewModel.loadingSubject
            .subscribe(onNext: {[weak self] isLoading in
                if isLoading {
                    self?.showIndetermineHud()
                } else {
                    self?.hideHud()
                }
            })
            .disposed(by: disposeBag)
    }
}
