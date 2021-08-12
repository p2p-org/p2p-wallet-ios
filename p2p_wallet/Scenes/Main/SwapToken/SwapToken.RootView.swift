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
        lazy var reverseButton = UIImageView(width: 44, height: 44, cornerRadius: 12, image: .reverseButton)
            .onTap(viewModel, action: #selector(ViewModel.swapSourceAndDestination))
        lazy var destinationWalletView = SwapToken.WalletView(viewModel: viewModel, type: .destination)
        
        lazy var exchangeRateLabel = UILabel(textSize: 15, weight: .medium)
        lazy var exchangeRateReverseButton = UIImageView(width: 18, height: 18, image: .walletSwap, tintColor: .h8b94a9)
            .padding(.init(all: 3))
            .onTap(viewModel, action: #selector(ViewModel.reverseExchangeRate))
        
        lazy var slippageLabel = UILabel(textSize: 15, weight: .medium, numberOfLines: 0)
        
        lazy var swapFeeLabel = UILabel(text: L10n.swapFees, textSize: 15, weight: .medium)
        lazy var errorLabel = UILabel(textSize: 15, weight: .medium, textColor: .alert, numberOfLines: 0)
        
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
            stackView.spacing = 16
            stackView.addArrangedSubviews {
                sourceWalletView
                
                swapSourceAndDestinationView()
                
                destinationWalletView
                
                createSectionView(
                    title: L10n.currentPrice,
                    contentView: exchangeRateLabel,
                    rightView: exchangeRateReverseButton
                )
                    .withTag(1)
                
                createSectionView(
                    title: L10n.maxPriceSlippage,
                    contentView: slippageLabel
                )
                    .onTap(viewModel, action: #selector(ViewModel.chooseSlippage))
                    .withTag(2)
                
                createSectionView(
                    label: swapFeeLabel,
                    contentView: errorLabel
                )
                    .withModifier { view in
                        let view = view
                        view.autoSetDimension(.height, toSize: 48, relation: .greaterThanOrEqual)
                        return view
                    }
                    .withTag(3)
                
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
                .drive(stackView.viewWithTag(1)!.rx.isHidden)
                .disposed(by: disposeBag)
            
            isNoPoolAvailable
                .drive(stackView.viewWithTag(3)!.rx.isHidden)
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
            
            // fee
//            Driver.combineLatest(
//                viewModel.output.liquidityProviderFee,
//                viewModel.output.destinationWallet.map {$0?.token.symbol}
//            )
//                .map {fee, symbol -> String? in
//                    guard let fee = fee, let symbol = symbol else {return nil}
//                    return fee.toString(maximumFractionDigits: 9) + " " + symbol
//                }
//                .drive(liquidityProviderFeeLabel.rx.text)
//                .disposed(by: disposeBag)
            
//            Driver.combineLatest(
//                viewModel.output.sourceWallet,
//                viewModel.output.destinationWallet,
//                viewModel.output.feeInLamports
//            )
//                .map {source, destination, lamports -> String? in
//                    guard let lamports = lamports else {return nil}
//                    var value: Double = 0
//                    var symbol = "SOL"
//                    if SwapToken.isFeeRelayerEnabled(source: source, destination: destination) {
//                        value = lamports.convertToBalance(decimals: source?.token.decimals)
//                        symbol = source?.token.symbol ?? ""
//                    } else {
//                        value = lamports.convertToBalance(decimals: 9)
//                    }
//                    return "\(value.toString(maximumFractionDigits: 9)) \(symbol)"
//                }
//                .drive(feeLabel.rx.text)
//                .disposed(by: disposeBag)
            
            // slippage
            viewModel.output.slippage
                .drive(onNext: {[weak self] slippage in
                    if slippage > .maxSlippage {
                        self?.slippageLabel.attributedText = NSMutableAttributedString()
                            .text((slippage * 100).toString(maximumFractionDigits: 9) + "%", weight: .medium)
                            .text(" ", weight: .medium)
                            .text(L10n.slippageExceedsMaximum, weight: .medium, color: .red)
                    } else if slippage > .frontrunSlippage && slippage <= .maxSlippage {
                        self?.slippageLabel.attributedText = NSMutableAttributedString()
                            .text((slippage * 100).toString(maximumFractionDigits: 9) + "%", weight: .medium)
                            .text(" ", weight: .medium)
                            .text(L10n.yourTransactionMayBeFrontrun, weight: .medium, color: .attentionGreen)
                    } else {
                        self?.slippageLabel.text = (slippage * 100).toString(maximumFractionDigits: 9) + "%"
                    }
                })
                .disposed(by: disposeBag)
            
            // error
            viewModel.output.error
                .drive(errorLabel.rx.text)
                .disposed(by: disposeBag)
            
            let errorHidden = viewModel.output.error
                .map {
                    $0 == nil ||
                    [
                        L10n.insufficientFunds,
                        L10n.amountIsNotValid,
                        L10n.yourAccountDoesNotHaveEnoughTokensToCoverFee,
                        L10n.slippageIsnTValid
                    ].contains($0)
                }
                
            errorHidden
                .drive(errorLabel.rx.isHidden)
                .disposed(by: disposeBag)
            
            errorHidden
                .drive(onNext: {[weak self] isErrorHidden in
                    var textSize: CGFloat = 15
                    var textColor: UIColor = .textBlack
                    if !isErrorHidden {
                        textSize = 13
                        textColor = .textSecondary
                    }
                    self?.swapFeeLabel.font = .systemFont(ofSize: textSize)
                    self?.swapFeeLabel.textColor = textColor
                })
                .disposed(by: disposeBag)
            
//            viewModel.output.error
//                .map {$0 != L10n.yourAccountDoesNotHaveEnoughTokensToCoverFee}
//                .drive(feeAlertImageView.rx.isHidden)
//                .disposed(by: disposeBag)
//
//            viewModel.output.error
//                .map {$0 != L10n.yourAccountDoesNotHaveEnoughTokensToCoverFee}
//                .map {$0 ? UIColor.textSecondary: UIColor.alert}
//                .drive(feeLabel.rx.textColor)
//                .disposed(by: disposeBag)
            
            // swap button
            viewModel.output.isValid
                .drive(swapButton.rx.isEnabled)
                .disposed(by: disposeBag)
            
            viewModel.output.slippage
                .map {$0 > .maxSlippage ? L10n.enterANumberLessThanD(Int(Double.maxSlippage * 100)): L10n.swapNow}
                .drive(swapButton.rx.title())
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
        
        private func createSectionView(
            title: String? = nil,
            label: UIView? = nil,
            contentView: UIView,
            rightView: UIView = UIImageView(width: 6, height: 12, image: .nextArrow, tintColor: .h8b94a9.onDarkMode(.white)
            )
                .padding(.init(x: 9, y: 6))
        ) -> UIStackView {
            UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill) {
                UIView.defaultSeparator()
                UIStackView(axis: .horizontal, spacing: 5, alignment: .center, distribution: .fill) {
                    UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
                        label ?? UILabel(
                            text: title,
                            textSize: 13,
                            weight: .medium,
                            textColor: .textSecondary
                        )
                        contentView
                    }
                    
                    rightView
                }
            }
        }
    }
}
