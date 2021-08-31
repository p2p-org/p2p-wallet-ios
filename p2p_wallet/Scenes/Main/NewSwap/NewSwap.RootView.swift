//
//  SerumSwap.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/08/2021.
//

import UIKit
import RxSwift
import RxCocoa
import Action

extension NewSwap {
    class RootView: ScrollableVStackRootView {
        // MARK: - Constants
        private let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private let viewModel: NewSwapViewModelType
        
        // MARK: - Subviews
        private lazy var sourceWalletView = WalletView(viewModel: viewModel, type: .source)
        private lazy var reverseButton = UIImageView(width: 44, height: 44, cornerRadius: 12, image: .reverseButton)
            .onTap(self, action: #selector(swapSourceAndDestination))
        private lazy var destinationWalletView = WalletView(viewModel: viewModel, type: .destination)
        
        private lazy var exchangeRateLabel = UILabel(textSize: 15, weight: .medium)
//        private lazy var exchangeRateReverseButton = UIImageView(width: 18, height: 18, image: .walletSwap, tintColor: .h8b94a9)
//            .padding(.init(all: 3))
//            .onTap(self, action: #selector(reverseExchangeRate))
        
        private lazy var slippageLabel = UILabel(textSize: 15, weight: .medium, numberOfLines: 0)
        
        private lazy var swapFeeLabel = UILabel(text: L10n.swapFees, textSize: 15, weight: .medium)
        private lazy var errorLabel = UILabel(textSize: 15, weight: .medium, textColor: .alert, numberOfLines: 0)
        
        private lazy var swapButton = WLButton.stepButton(type: .blue, label: L10n.swapNow)
            .onTap(self, action: #selector(authenticateAndSwap))
        
        // MARK: - Initializers
        init(viewModel: NewSwapViewModelType) {
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
                    rightView: nil, // exchangeRateReverseButton
                    addSeparatorOnTop: false
                )
                    .withTag(1)
                
                UIView.defaultSeparator()
                    .withTag(2)
                
                createSectionView(
                    title: L10n.maxPriceSlippage,
                    contentView: slippageLabel,
                    addSeparatorOnTop: false
                )
                    .onTap(self, action: #selector(chooseSlippage))
                    .withTag(3)
                
                UIView.defaultSeparator()
                    .withTag(4)
                
                createSectionView(
                    label: swapFeeLabel,
                    contentView: errorLabel,
                    addSeparatorOnTop: false
                )
                    .withModifier { view in
                        let view = view
                        view.autoSetDimension(.height, toSize: 48, relation: .greaterThanOrEqual)
                        return view
                    }
                    .onTap(self, action: #selector(showSwapFees))
                    .withTag(5)
                
                errorLabel
                
                swapButton
                
                BEStackViewSpacing(20)
                UIStackView(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill) {
                    UILabel(text: L10n.poweredBy, textSize: 13, textColor: .textSecondary, textAlignment: .center)
                    viewModel.providerSignatureView()
                }
                    .centeredHorizontallyView
            }
        }
        
        private func bind() {
            // exchange rate
            let isRateNil = viewModel.exchangeRateDriver
                .map {$0 == nil}
            
            isRateNil.drive(stackView.viewWithTag(1)!.rx.isHidden)
                .disposed(by: disposeBag)
            
            isRateNil.drive(stackView.viewWithTag(2)!.rx.isHidden)
                .disposed(by: disposeBag)
            
            Driver.combineLatest(
                viewModel.exchangeRateDriver,
                viewModel.sourceWalletDriver,
                viewModel.destinationWalletDriver
            )
                .map {exrate, source, destination -> String? in
                    guard let exrate = exrate, let source = source, let destination = destination
                    else {return nil}
                    
                    var string = exrate.toString(maximumFractionDigits: 9)
                    string += " "
                    string += source.token.symbol
                    string += " "
                    string += L10n.per
                    string += " "
                    string += destination.token.symbol
                    return string
                }
                .drive(exchangeRateLabel.rx.text)
                .disposed(by: disposeBag)
            
            // slippage
            viewModel.slippageDriver
                .map {slippageAttributedText(slippage: $0 ?? 0)}
                .drive(slippageLabel.rx.attributedText)
                .disposed(by: disposeBag)
            
            // fee
            let isFeeNil = viewModel.feesDriver.map {$0.isEmpty}
            
            isFeeNil.drive(stackView.viewWithTag(4)!.rx.isHidden)
                .disposed(by: disposeBag)
            
            isFeeNil.drive(stackView.viewWithTag(5)!.rx.isHidden)
                .disposed(by: disposeBag)
            
            // error
            let isErrorHidden = viewModel.errorDriver
                .map {
                    $0 == nil ||
                    [
                        L10n.insufficientFunds,
                        L10n.amountIsNotValid,
                        L10n.slippageIsnTValid,
                        L10n.someParametersAreMissing
                    ].contains($0)
                }
            
            isErrorHidden
                .drive(errorLabel.rx.isHidden)
                .disposed(by: disposeBag)
            
            isErrorHidden
                .drive(onNext: {[weak self] isErrorHidden in
                    var textSize: CGFloat = 15
                    var textColor: UIColor = .textBlack
                    if !isErrorHidden {
                        textSize = 13
                        textColor = .textSecondary
                    }
                    self?.swapFeeLabel.font = .systemFont(ofSize: textSize, weight: .medium)
                    self?.swapFeeLabel.textColor = textColor
                })
                .disposed(by: disposeBag)
            
            viewModel.errorDriver
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
            
            viewModel.errorDriver
                .drive(errorLabel.rx.text)
                .disposed(by: disposeBag)
            
            // button
            viewModel.isSwappableDriver
                .drive(swapButton.rx.isEnabled)
                .disposed(by: disposeBag)
            
            Driver.combineLatest(
                viewModel.sourceWalletDriver.map {$0 == nil},
                viewModel.destinationWalletDriver.map {$0 == nil},
                viewModel.inputAmountDriver,
                viewModel.errorDriver
            )
                .map {isSourceWalletEmpty, isDestinationWalletEmpty, amount, error -> String? in
                    if isSourceWalletEmpty || isDestinationWalletEmpty {
                        return L10n.selectToken
                    }
                    if amount == nil {
                        return L10n.enterTheAmount
                    }
                    if error == L10n.slippageIsnTValid {
                        return L10n.enterANumberLessThanD(Int(Double.maxSlippage * 100))
                    }
                    if error == L10n.insufficientFunds {
                        return L10n.donTGoOverTheAvailableFunds
                    }
                    return L10n.swapNow
                }
                    .drive(swapButton.rx.title())
                    .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc private func swapSourceAndDestination() {
            viewModel.swapSourceAndDestination()
        }
        
//        @objc private func reverseExchangeRate() {
//            viewModel.reverseExchangeRate()
//        }
        
        @objc private func authenticateAndSwap() {
            viewModel.authenticateAndSwap()
        }
        
        @objc private func chooseSlippage() {
            viewModel.navigate(to: .chooseSlippage)
        }
        
        @objc private func showSwapFees() {
            viewModel.navigate(to: .swapFees)
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
