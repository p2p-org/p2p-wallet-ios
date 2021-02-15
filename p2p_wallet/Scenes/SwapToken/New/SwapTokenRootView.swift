//
//  SwapTokenRootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/02/2021.
//

import UIKit
import RxSwift
import Action

class SwapTokenRootView: ScrollableVStackRootView {
    // MARK: - Constants
    
    // MARK: - Properties
    let viewModel: SwapTokenViewModel
    let disposeBag = DisposeBag()
    
    // MARK: - Subviews
    lazy var availableSourceBalanceLabel = UILabel(text: "Available", textColor: .h5887ff)
        .onTap(viewModel, action: #selector(SwapTokenViewModel.useAllBalance))
    lazy var destinationBalanceLabel = UILabel(textColor: .textSecondary)
    lazy var sourceWalletView = SwapTokenItemView(forAutoLayout: ())
    lazy var destinationWalletView = SwapTokenItemView(forAutoLayout: ())
    
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
        destinationWalletView.equityValueLabel.isHidden = true
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
                UILabel(text: L10n.from),
                availableSourceBalanceLabel
            ]),
            sourceWalletView,
            BEStackViewSpacing(8),
            swapSourceAndDestinationView(),
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
        bindViewModelToViews()
        bindControlsToViewModel()
    }
    
    func bindViewModelToViews() {
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
            })
            .disposed(by: disposeBag)
        
        // text fields
        viewModel.sourceAmountInput
            .distinctUntilChanged()
            .map { $0 == nil ? nil: $0.toString(maximumFractionDigits: 9, groupingSeparator: nil) }
            .asDriver(onErrorJustReturn: nil)
            .drive(sourceWalletView.amountTextField.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.destinationAmountInput
            .distinctUntilChanged()
            .map { $0 == nil ? nil: $0.toString(maximumFractionDigits: 9, groupingSeparator: nil) }
            .asDriver(onErrorJustReturn: nil)
            .drive(destinationWalletView.amountTextField.rx.text)
            .disposed(by: disposeBag)
        
        // exchange rate label
        Observable.combineLatest(
            viewModel.sourceWallet,
            viewModel.sourceAmountInput,
            viewModel.destinationWallet,
            viewModel.destinationAmountInput,
            viewModel.isReversedExchangeRate
        )
            .map {sourceWallet, sourceAmount, destinationWallet, destinationAmount, isReversed -> String? in
                guard let amountIn = sourceAmount,
                      let amountOut = destinationAmount,
                      var fromSymbol = sourceWallet?.symbol,
                      var toSymbol = destinationWallet?.symbol,
                      var fromDecimals = sourceWallet?.decimals,
                      var toDecimals = destinationWallet?.decimals
                else {
                    return nil
                }
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
                      let lamports = amountInput?.toLamport(decimals: decimals),
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
    }
    
    func bindControlsToViewModel() {
        sourceWalletView.amountTextField.rx.text
            .distinctUntilChanged()
            .map {$0 == nil ? nil: Double($0!)}
            .bind(to: viewModel.sourceAmountInput)
            .disposed(by: disposeBag)
        
        destinationWalletView.amountTextField.rx.text
            .distinctUntilChanged()
            .map {$0 == nil ? nil: Double($0!)}
            .bind(to: viewModel.destinationAmountInput)
            .disposed(by: disposeBag)
    }
}
