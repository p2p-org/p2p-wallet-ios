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
        lazy var sourceWalletView = WalletView(viewModel: viewModel, type: .source)
        lazy var destinationWalletView = SwapToken.WalletView(viewModel: viewModel, type: .destination)
        
        lazy var exchangeRateLabel = UILabel(text: nil)
        lazy var exchangeRateReverseButton = UIImageView(width: 18, height: 18, image: .walletSwap, tintColor: .h8b94a9)
            .onTap(viewModel, action: #selector(ViewModel.reverseExchangeRate))
        
        lazy var reverseButton = UIImageView(width: 44, height: 44, cornerRadius: 12, image: .reverseButton)
            .onTap(viewModel, action: #selector(ViewModel.swapSourceAndDestination))
        
        lazy var minimumReceiveLabel = UILabel(textColor: .textSecondary, textAlignment: .right)
        lazy var liquidityProviderFeeLabel = UILabel(textColor: .textSecondary, textAlignment: .right)
        lazy var feeLabel = UILabel(textColor: .textSecondary, textAlignment: .right)
        lazy var feeAlertImageView = UIImageView(width: 20, height: 20, image: .alert, tintColor: .alert)
        lazy var slippageLabel = UILabel(textColor: .textSecondary, textAlignment: .right)
        
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
            layout()
            bind()
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
        }
        
        // MARK: - Layout
        private func layout() {
            stackView.spacing = 30
            stackView.addArrangedSubviews {
                sourceWalletView
                BEStackViewSpacing(16)
                swapSourceAndDestinationView()
                BEStackViewSpacing(16)
                destinationWalletView
                UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill) {
                    UILabel(text: L10n.price + ": ", weight: .medium, textColor: .a3a5baStatic.onDarkMode(.white))
                    exchangeRateLabel
                        .withContentHuggingPriority(.required, for: .horizontal)
                    exchangeRateReverseButton
                }
                    .padding(.init(all: 8), backgroundColor: .grayPanel, cornerRadius: 12)
                UIView.defaultSeparator()
                UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill) {
                    UILabel(text: L10n.minimumReceive + ": ", textColor: .textSecondary)
                    minimumReceiveLabel
                }
                BEStackViewSpacing(16)
                UIStackView(axis: .horizontal, spacing: 10, alignment: .top, distribution: .fill) {
                    UILabel(text: L10n.liquidityProviderFee + ":", textColor: .textSecondary)
                        .adjustsFontSizeToFitWidth()
                        .withContentHuggingPriority(.defaultLow, for: .horizontal)
                        .withContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                    liquidityProviderFeeLabel
                        .withContentHuggingPriority(.required, for: .horizontal)
                        .withContentCompressionResistancePriority(.required, for: .horizontal)
                }
                BEStackViewSpacing(16)
                UIStackView(axis: .horizontal, spacing: 10, alignment: .top, distribution: .fill) {
                    UILabel(text: L10n.fee + ":", textColor: .textSecondary)
                        .adjustsFontSizeToFitWidth()
                        .withContentHuggingPriority(.defaultLow, for: .horizontal)
                        .withContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                    feeLabel
                        .withContentHuggingPriority(.required, for: .horizontal)
                        .withContentCompressionResistancePriority(.required, for: .horizontal)
                    BEStackViewSpacing(5)
                    feeAlertImageView
                        .withContentHuggingPriority(.required, for: .horizontal)
                        .withContentCompressionResistancePriority(.required, for: .horizontal)
                }
                BEStackViewSpacing(16)
                UIStackView(axis: .horizontal, spacing: 10, alignment: .fill, distribution: .fill) {
                    UILabel(text: L10n.slippage + ": ", textColor: .textSecondary)
                    slippageLabel
                }
                    .onTap(viewModel, action: #selector(ViewModel.chooseSlippage))
                errorLabel
                BEStackViewSpacing(16)
                swapButton
                BEStackViewSpacing(20)
                UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
                    UILabel(text: L10n.poweredBy, textSize: 13, textColor: .textSecondary, textAlignment: .center)
                    UIImageView(width: 24, height: 24, image: .orcaLogo)
                    UIImageView(width: 68, height: 13, image: .orcaText, tintColor: .textBlack)
                }
                    .centeredHorizontallyView
                BEStackViewSpacing(20)
                UIView.defaultSeparator()
                BEStackViewSpacing(10)
                UIView.allDepositsAreStored100NonCustodiallityWithKeysHeldOnThisDevice()
            }
        }
        
        private func bind() {
            // loaded
            viewModel.output.error
                .map { $0 == L10n.swappingIsCurrentlyUnavailable }
                .drive(onNext: {[weak self] isUnavailable in
                    self?.removeErrorView()
                    self?.stackView.isHidden = false
                    
                    if isUnavailable {
                        self?.stackView.isHidden = true
                        self?.showErrorView(
                            title: L10n.swappingIsCurrentlyUnavailable,
                            description: L10n.swappingPoolsNotFound + "\n" + L10n.pleaseTryAgainLater,
                            retryAction: CocoaAction { [weak self] in
                                self?.viewModel.reload()
                                return .just(())
                            }
                        )
                    }
                })
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
                .drive(liquidityProviderFeeLabel.superview!.rx.isHidden)
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
                        guard estimatedAmount != 0 else {return nil}
                        rate = amount / estimatedAmount
                        fromSymbol = destinationSymbol
                        toSymbol = sourceSymbol
                    } else {
                        guard amount != 0 else {return nil}
                        rate = estimatedAmount / amount
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
                viewModel.output.liquidityProviderFee,
                viewModel.output.destinationWallet.map {$0?.token.symbol}
            )
                .map {fee, symbol -> String? in
                    guard let fee = fee, let symbol = symbol else {return nil}
                    return fee.toString(maximumFractionDigits: 9) + " " + symbol
                }
                .drive(liquidityProviderFeeLabel.rx.text)
                .disposed(by: disposeBag)
            
            Driver.combineLatest(
                viewModel.output.sourceWallet,
                viewModel.output.destinationWallet,
                viewModel.output.feeInLamports
            )
                .map {source, destination, lamports -> String? in
                    guard let lamports = lamports else {return nil}
                    var value: Double = 0
                    var symbol = "SOL"
                    if SwapToken.isFeeRelayerEnabled(source: source, destination: destination) {
                        value = lamports.convertToBalance(decimals: source?.token.decimals)
                        symbol = source?.token.symbol ?? ""
                    } else {
                        value = lamports.convertToBalance(decimals: 9)
                    }
                    return "\(value.toString(maximumFractionDigits: 9)) \(symbol)"
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
                        self?.slippageLabel.text = (slippage * 100).toString(maximumFractionDigits: 9) + " %"
                    }
                })
                .disposed(by: disposeBag)
            
            // error
            viewModel.output.error
                .drive(errorLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.output.error
                .map {$0 == nil || $0 == L10n.insufficientFunds || $0 == L10n.amountIsNotValid || $0 == L10n.yourAccountDoesNotHaveEnoughTokensToCoverFee}
                .drive(errorLabel.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.output.error
                .map {$0 != L10n.yourAccountDoesNotHaveEnoughTokensToCoverFee}
                .drive(feeAlertImageView.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.output.error
                .map {$0 != L10n.yourAccountDoesNotHaveEnoughTokensToCoverFee}
                .map {$0 ? UIColor.textSecondary: UIColor.alert}
                .drive(feeLabel.rx.textColor)
                .disposed(by: disposeBag)
            
            // swap button
            viewModel.output.isValid
                .drive(swapButton.rx.isEnabled)
                .disposed(by: disposeBag)
        }
        
        // MARK: - Helpers
        private func swapSourceAndDestinationView() -> UIView {
            let view = UIView(forAutoLayout: ())
            let separator = UIView.defaultSeparator()
            view.addSubview(separator)
            separator.autoPinEdge(toSuperviewEdge: .leading, withInset: 8)
            separator.autoAlignAxis(toSuperviewAxis: .horizontal)
            
            view.addSubview(reverseButton)
            reverseButton.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .leading)
            separator.autoPinEdge(.trailing, to: .leading, of: reverseButton, withOffset: -8)
            
            return view
        }
    }
}
