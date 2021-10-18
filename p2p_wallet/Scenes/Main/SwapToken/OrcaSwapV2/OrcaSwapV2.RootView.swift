//
//  OrcaSwapV2.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import UIKit
import RxSwift
import RxCocoa

extension OrcaSwapV2 {
    class RootView: ScrollableVStackRootView {
        // MARK: - Constants
        let disposeBag = DisposeBag()
        
        // MARK: - Properties
        let viewModel: OrcaSwapV2ViewModelType
        
        // MARK: - Subviews
        lazy var sourceWalletView = WalletView(viewModel: viewModel, type: .source)
        lazy var reverseButton = UIImageView(width: 44, height: 44, cornerRadius: 12, image: .reverseButton)
            .onTap(self, action: #selector(swapSourceAndDestination))
        lazy var destinationWalletView = WalletView(viewModel: viewModel, type: .destination)
        
        lazy var loadingRoutesIndicatorView: UIActivityIndicatorView = {
            let indicator = UIActivityIndicatorView()
            indicator.startAnimating()
            return indicator
        }()
        
        lazy var loadingRoutesLabel = UILabel(text: L10n.findingSwappingRoutes, textColor: .textSecondary, numberOfLines: 2)
            .onTap(self, action: #selector(retryLoadingRoutes))
        
        lazy var exchangeRateLabel = UILabel(textSize: 15, weight: .medium)
        lazy var exchangeRateReverseButton = UIImageView(width: 18, height: 18, image: .walletSwap, tintColor: .h8b94a9)
            .padding(.init(all: 3))
            .onTap(self, action: #selector(reverseExchangeRate))
        
        lazy var slippageLabel = UILabel(textSize: 15, weight: .medium, numberOfLines: 0)
        
        lazy var swapFeeLabel = UILabel(text: L10n.swapFees, textSize: 15, weight: .medium)
        lazy var errorLabel = UILabel(textSize: 15, weight: .medium, textColor: .alert, numberOfLines: 0, textAlignment: .center)
        
        lazy var swapButton = WLButton.stepButton(type: .blue, label: L10n.swapNow)
            .onTap(self, action: #selector(authenticateAndSwap))
        
        // MARK: - Methods
        init(viewModel: OrcaSwapV2ViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
        }
        
        override func commonInit() {
            super.commonInit()
            layout()
            bind()
        }
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            viewModel.reload()
        }
        
        // MARK: - Layout
        private func layout() {
            stackView.spacing = 16
            stackView.addArrangedSubviews {
                sourceWalletView
                
                swapSourceAndDestinationView()
                
                destinationWalletView
                
                BEStackViewSpacing(8)
                
                UIStackView(axis: .horizontal, spacing: 8, alignment: .fill, distribution: .fill) {
                    loadingRoutesIndicatorView
                        .withContentHuggingPriority(.required, for: .horizontal)
                    loadingRoutesLabel
                        .withContentHuggingPriority(.required, for: .vertical)
                }
                    .withContentHuggingPriority(.required, for: .vertical)
                
                BEStackViewSpacing(16)
                
                OrcaSwapV2.createSectionView(
                    title: L10n.currentPrice,
                    contentView: exchangeRateLabel,
                    rightView: exchangeRateReverseButton,
                    addSeparatorOnTop: false
                )
                    .withTag(1)
                
                UIView.defaultSeparator()
                    .withTag(2)
                
                OrcaSwapV2.createSectionView(
                    title: L10n.maxPriceSlippage,
                    contentView: slippageLabel,
                    addSeparatorOnTop: false
                )
                    .onTap(self, action: #selector(chooseSlippage))
                    .withTag(3)
                
                UIView.defaultSeparator()
                    .withTag(4)
                
                OrcaSwapV2.createSectionView(
                    label: swapFeeLabel,
                    contentView: nil,
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
                    UIImageView(width: 24, height: 24, image: .orcaLogo)
                    UIImageView(width: 68, height: 13, image: .orcaText, tintColor: .textBlack)
                }
                    .centeredHorizontallyView
            }
        }
        
        private func bind() {
            // loading swap
            viewModel.loadingStateDriver
                .drive(onNext: {[weak self] state in
                    self?.setUp(state, reloadAction: { [weak self] in
                        self?.viewModel.reload()
                    })
                })
                .disposed(by: disposeBag)
            
            // loading routes
            viewModel.isTokenPairValidDriver
                .drive(onNext: {[weak self] isValid in
                    self?.loadingRoutesIndicatorView.isHidden = true
                    self?.loadingRoutesLabel.isHidden = true
                    self?.loadingRoutesLabel.textColor = .textSecondary
                    self?.loadingRoutesLabel.isUserInteractionEnabled = false
                    
                    switch isValid.state {
                    case .loading:
                        self?.loadingRoutesIndicatorView.isHidden = false
                        self?.loadingRoutesLabel.isHidden = false
                        self?.loadingRoutesLabel.text = L10n.findingSwappingRoutes
                    case .error:
                        self?.loadingRoutesLabel.isHidden = false
                        self?.loadingRoutesLabel.textColor = .alert
                        self?.loadingRoutesLabel.text = L10n.ErrorFindingSwappingRoutes.tapHereToTryAgain
                    default:
                        break
                    }
                })
                .disposed(by: disposeBag)
            
            // exchange rate
            let isTokenPairInvalidDriver = viewModel.isTokenPairValidDriver.map {$0.value != true}

            isTokenPairInvalidDriver
                .drive(stackView.viewWithTag(1)!.rx.isHidden)
                .disposed(by: disposeBag)
            
            isTokenPairInvalidDriver
                .drive(stackView.viewWithTag(2)!.rx.isHidden)
                .disposed(by: disposeBag)
            
            Driver.combineLatest(
                viewModel.exchangeRateDriver,
                viewModel.isExchangeRateReversed,
                viewModel.sourceWalletDriver,
                viewModel.destinationWalletDriver
            )
                .map { rate, isReversed, source, destination -> String? in
                    guard let rate = rate, let sourceSymbol = source?.token.symbol, let destinationSymbol = destination?.token.symbol
                    else {return nil}
                    
                    var fromSymbol = sourceSymbol
                    var toSymbol = destinationSymbol
                    if isReversed {
                        fromSymbol = destinationSymbol
                        toSymbol = sourceSymbol
                    }
                    
                    return "\(rate.toString(maximumFractionDigits: 9)) \(toSymbol) \(L10n.per) \(fromSymbol)"
                }
                .drive(exchangeRateLabel.rx.text)
                .disposed(by: disposeBag)
            
            // slippage
            isTokenPairInvalidDriver
                .drive(stackView.viewWithTag(3)!.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.slippageDriver
                .map {slippageAttributedText(slippage: $0)}
                .drive(slippageLabel.rx.attributedText)
                .disposed(by: disposeBag)
            
            // swap fees
            
            // error
            #if DEBUG
            viewModel.errorDriver.map {$0 == nil}
                .drive(errorLabel.rx.isHidden)
                .disposed(by: disposeBag)
            
            viewModel.errorDriver
                .map {$0?.rawValue}
                .drive(errorLabel.rx.text)
                .disposed(by: disposeBag)
            #else
            errorLabel.isHidden = true
            #endif
            
            // button
            viewModel.errorDriver.map {$0 == nil}
                .drive(swapButton.rx.isEnabled)
                .disposed(by: disposeBag)
            
            Driver.combineLatest(
                viewModel.errorDriver,
                viewModel.sourceWalletDriver.map {$0?.token.symbol}
            )
                .map {error, sourceSymbol -> String in
                    switch error {
                    case .swappingIsNotAvailable:
                        return L10n.swappingIsCurrentlyUnavailable
                    case .sourceWalletIsEmpty:
                        return L10n.chooseSourceWallet
                    case .destinationWalletIsEmpty:
                        return L10n.chooseDestinationWallet
                    case .canNotSwapToItSelf:
                        return L10n.chooseAnotherDestinationWallet
                    case .tradablePoolsPairsNotLoaded:
                        return L10n.loading
                    case .tradingPairNotSupported:
                        return L10n.thisTradingPairIsNotSupported
                    case .feesIsBeingCalculated:
                        return L10n.calculatingFees
                    case .couldNotCalculatingFees:
                        return L10n.couldNotCalculatingFees
                    case .inputAmountIsEmpty:
                        return L10n.enterInputAmount
                    case .inputAmountIsNotValid:
                        return L10n.inputAmountIsNotValid
                    case .insufficientFunds:
                        return L10n.insufficientFunds
                    case .estimatedAmountIsNotValid:
                        return L10n.amountIsTooSmall
                    case .bestPoolsPairsIsEmpty:
                        return L10n.thisTradingPairIsNotSupported
                    case .slippageIsNotValid:
                        return L10n.chooseAnotherSlippage
                    case .nativeWalletNotFound:
                        return L10n.couldNotConnectToWallet
                    case .notEnoughSOLToCoverFees:
                        return L10n.yourAccountDoesNotHaveEnoughSOLToCoverFee
                    case .notEnoughBalanceToCoverFees:
                        return L10n.yourAccountDoesNotHaveEnoughToCoverFees(sourceSymbol ?? "")
                    case .unknown:
                        return L10n.unknownError
                    case .none:
                        return L10n.swapNow
                    }
                }
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
        
        @objc func swapSourceAndDestination() {
            viewModel.swapSourceAndDestination()
        }
        
        @objc func reverseExchangeRate() {
            viewModel.reverseExchangeRate()
        }
        
        @objc func authenticateAndSwap() {
            viewModel.authenticateAndSwap()
        }
        
        @objc func chooseSlippage() {
            viewModel.navigate(to: .chooseSlippage)
        }
        
        @objc func showSwapFees() {
            viewModel.navigate(to: .swapFees)
        }
        
        @objc func retryLoadingRoutes() {
            viewModel.retryLoadingRoutes()
        }
    }
}
