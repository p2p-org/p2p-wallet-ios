//
//  SwapToken.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/06/2021.
//

import UIKit
import RxSwift
import Action
import RxCocoa

extension SwapToken {
    class RootView: ScrollableVStackRootView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        let viewModel: ViewModel
        
        // MARK: - Subviews
        lazy var availableSourceBalanceLabel = UILabel(text: "Available", weight: .medium, textColor: .h5887ff)
            .onTap(viewModel, action: #selector(ViewModel.useAllBalance))
        lazy var destinationBalanceLabel = UILabel(weight: .medium, textColor: .textSecondary)
        lazy var sourceWalletView = SwapToken.WalletView(forAutoLayout: ())
        lazy var destinationWalletView = SwapToken.WalletView(forAutoLayout: ())
        
        lazy var exchangeRateLabel = UILabel(text: nil)
        lazy var exchangeRateReverseButton = UIImageView(width: 18, height: 18, image: .walletSwap, tintColor: .h8b94a9)
            .onTap(viewModel, action: #selector(ViewModel.reverseExchangeRate))
        
        lazy var reverseButton = UIImageView(width: 44, height: 44, cornerRadius: 12, image: .reverseButton)
            .onTap(viewModel, action: #selector(ViewModel.swapSourceAndDestination))
        
        lazy var minimumReceiveLabel = UILabel(textColor: .textSecondary)
        lazy var feeLabel = UILabel(textColor: .textSecondary)
        lazy var slippageLabel = UILabel(textColor: .textSecondary)
        
        lazy var errorLabel = UILabel(textSize: 12, weight: .medium, textColor: .red, numberOfLines: 0, textAlignment: .center)
        
        lazy var swapButton = WLButton.stepButton(type: .blue, label: L10n.swapNow)
            .onTap(viewModel, action: #selector(ViewModel.authenticateAndSwap))
        
        // MARK: - Initializers
        init(viewModel: ViewModel) {
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
            sourceWalletView.chooseTokenAction = CocoaAction { [weak self] in
                self?.viewModel.chooseSourceWallet()
                return .just(())
            }
            
            destinationWalletView.chooseTokenAction = CocoaAction { [weak self] in
                self?.viewModel.chooseDestinationWallet()
                return .just(())
            }
            
            // set up textfields
            sourceWalletView.amountTextField.delegate = self
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
        }
        
        // MARK: - Layout
        private func layout() {
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
                .onTap(viewModel, action: #selector(ViewModel.chooseSlippage)),
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
        
        private func bind() {
            // isLoading
            
            // error
            
            // available amount
            Driver.combineLatest(
                viewModel.output.availableAmount,
                viewModel.output.sourceWallet
            )
                .map {amount, wallet in
                    L10n.available + ": " + amount?.toString(maximumFractionDigits: 9) + " " + wallet?.token.symbol
                }
                .drive(availableSourceBalanceLabel.rx.text)
                .disposed(by: disposeBag)
            
            // source wallet
            viewModel.output.sourceWallet
                .drive(onNext: {[weak self] wallet in
                    self?.sourceWalletView.setUp(wallet: wallet)
                })
                .disposed(by: disposeBag)
            
            // destination wallet
            viewModel.output.destinationWallet
                .drive(onNext: { [weak self] wallet in
                    self?.destinationWalletView.setUp(wallet: wallet)
                    if let amount = wallet?.amount?.toString(maximumFractionDigits: 9) {
                        self?.destinationBalanceLabel.text = L10n.balance + ": " + amount + " " + "\(wallet?.token.symbol ?? "")"
                    } else {
                        self?.destinationBalanceLabel.text = nil
                    }
                })
                .disposed(by: disposeBag)
            
            // textFields
            sourceWalletView.amountTextField.rx.text
                .bind(to: viewModel.input.amount)
                .disposed(by: disposeBag)
            
            destinationWalletView.amountTextField.rx.text
                .bind(to: viewModel.input.estimatedAmount)
                .disposed(by: disposeBag)
            
            viewModel.output.amount
                .map {$0?.toString(maximumFractionDigits: 9, groupingSeparator: "")}
                .drive(sourceWalletView.amountTextField.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.output.estimatedAmount
                .map {$0?.toString(maximumFractionDigits: 9, groupingSeparator: "")}
                .drive(destinationWalletView.amountTextField.rx.text)
                .disposed(by: disposeBag)
            
            // equity value label
            // FIXME: - price observing
            Driver.combineLatest(
                viewModel.output.amount,
                viewModel.output.sourceWallet
            )
                .map {amount, wallet in
                    if let wallet = wallet {
                        let value = amount * wallet.priceInCurrentFiat
                        return "≈ \(value.toString(maximumFractionDigits: 9)) \(Defaults.fiat.symbol)"
                    } else {
                        return L10n.selectCurrency
                    }
                }
                .drive(self.sourceWalletView.equityValueLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.output.destinationWallet
                .map {destinationWallet -> String? in
                    if destinationWallet != nil {
                        return nil
                    } else {
                        return L10n.selectCurrency
                    }
                }
                .drive(self.sourceWalletView.equityValueLabel.rx.text)
                .disposed(by: disposeBag)
            
            // pool
            let isNoPoolAvailable = viewModel.output.pool.map {$0 == nil}
            
            isNoPoolAvailable
                .drive(exchangeRateLabel.superview!.superview!.rx.isHidden)
                .disposed(by: disposeBag)
            
            isNoPoolAvailable
                .drive(minimumReceiveLabel.superview!.rx.isHidden)
                .disposed(by: disposeBag)
            
            isNoPoolAvailable
                .drive(feeLabel.superview!.rx.isHidden)
                .disposed(by: disposeBag)
            
            isNoPoolAvailable
                .drive(slippageLabel.superview!.rx.isHidden)
                .disposed(by: disposeBag)
            
            // exchange rate label
            Driver.combineLatest(
                viewModel.output.amount,
                viewModel.output.estimatedAmount,
                viewModel.output.isExchageRateReversed,
                viewModel.output.sourceWallet.map {$0?.token.symbol},
                viewModel.output.destinationWallet.map {$0?.token.symbol}
            )
                .map {amount, estimatedAmount, isReversed, sourceSymbol, destinationSymbol -> String? in
                    guard let amount = amount, let estimatedAmount = estimatedAmount, let sourceSymbol = sourceSymbol, let destinationSymbol = destinationSymbol
                    else {return nil}
                    
                    let rate: Double
                    let fromSymbol: String
                    let toSymbol: String
                    if isReversed {
                        guard amount != 0 else {return nil}
                        rate = estimatedAmount / amount
                        fromSymbol = destinationSymbol
                        toSymbol = sourceSymbol
                    } else {
                        guard estimatedAmount != 0 else {return nil}
                        rate = amount / estimatedAmount
                        fromSymbol = sourceSymbol
                        toSymbol = destinationSymbol
                    }
                    
                    var string = rate.toString(maximumFractionDigits: 9)
                    string += " "
                    string += toSymbol
                    string += " "
                    string += L10n.per
                    string += " "
                    string += fromSymbol
                    
                    return string
                }
                .drive(exchangeRateLabel.rx.text)
                .disposed(by: disposeBag)
            
            // minimum receive amount
            Driver.combineLatest(
                viewModel.output.minimumReceiveAmount,
                viewModel.output.destinationWallet
            )
                .map {minReceiveAmount, wallet -> String? in
                    guard let symbol = wallet?.token.symbol else {return nil}
                    return minReceiveAmount?.toString(maximumFractionDigits: 9) + " " + symbol
                }
                .drive(minimumReceiveLabel.rx.text)
                .disposed(by: disposeBag)
            
            // fee
            Driver.combineLatest(
                viewModel.output.fee,
                viewModel.output.destinationWallet.map {$0?.token.symbol}
            )
                .map {fee, symbol -> String? in
                    guard let fee = fee, let symbol = symbol else {return nil}
                    return fee.toString(maximumFractionDigits: 9) + " " + symbol
                }
                .drive(feeLabel.rx.text)
                .disposed(by: disposeBag)
            
            // slippage
            viewModel.output.slippage
                .drive(onNext: {[weak self] slippage in
                    if !(self?.viewModel.isSlippageValid(slippage: slippage) ?? true) {
                        self?.slippageLabel.attributedText = NSMutableAttributedString()
                            .text((slippage * 100).toString() + " %", color: .red)
                            .text(" ")
                            .text("(\(L10n.max). 20%)", color: .textSecondary)
                    } else {
                        self?.slippageLabel.text = (slippage * 100).toString() + " %"
                    }
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Helpers
        private func swapSourceAndDestinationView() -> UIView {
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
}

// MARK: - TextField delegate
extension SwapToken.RootView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let textField = textField as? TokenAmountTextField {
            return textField.shouldChangeCharactersInRange(range, replacementString: string)
        }
        return true
    }
}
