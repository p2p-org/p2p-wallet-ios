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
        lazy var loadingRoutesView: UIStackView = {
            let indicator = UIActivityIndicatorView()
            indicator.startAnimating()
            let view = UIStackView(axis: .horizontal, spacing: 8, alignment: .fill, distribution: .fill) {
                indicator
                UILabel(text: L10n.findingSwappingRoutes, textColor: .textSecondary)
            }
            return view
        }()
        lazy var routesView = UILabel(text: nil)
        
        lazy var exchangeRateLabel = UILabel(textSize: 15, weight: .medium)
        lazy var exchangeRateReverseButton = UIImageView(width: 18, height: 18, image: .walletSwap, tintColor: .h8b94a9)
            .padding(.init(all: 3))
            .onTap(self, action: #selector(reverseExchangeRate))
        
        lazy var slippageLabel = UILabel(textSize: 15, weight: .medium, numberOfLines: 0)
        
        lazy var swapFeeLabel = UILabel(text: L10n.swapFees, textSize: 15, weight: .medium)
        lazy var errorLabel = UILabel(textSize: 15, weight: .medium, textColor: .alert, numberOfLines: 0)
        
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
                
                loadingRoutesView
                
                routesView
                
                BEStackViewSpacing(16)
                
                OrcaSwapV1.createSectionView(
                    title: L10n.currentPrice,
                    contentView: exchangeRateLabel,
                    rightView: exchangeRateReverseButton,
                    addSeparatorOnTop: false
                )
                    .withTag(1)
                
                UIView.defaultSeparator()
                    .withTag(2)
                
                OrcaSwapV1.createSectionView(
                    title: L10n.maxPriceSlippage,
                    contentView: slippageLabel,
                    addSeparatorOnTop: false
                )
                    .onTap(self, action: #selector(chooseSlippage))
                    .withTag(3)
                
                UIView.defaultSeparator()
                    .withTag(4)
                
                OrcaSwapV1.createSectionView(
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
                    switch isValid.state {
                    case .notRequested:
                        self?.routesView.isHidden = true
                        self?.loadingRoutesView.isHidden = true
                    case .loading:
                        self?.routesView.isHidden = true
                        self?.loadingRoutesView.isHidden = false
                    case .loaded:
                        self?.routesView.isHidden = false
                        self?.loadingRoutesView.isHidden = true
                    case .error(_):
                        self?.routesView.isHidden = false
                        self?.loadingRoutesView.isHidden = false
                        self?.routesView.text = L10n.noRoutesForSwappingCurrentTokenPair
                    }
                })
                .disposed(by: disposeBag)
            
            // best routes
            viewModel.bestPoolsPairDriver
                .withLatestFrom(
                    Driver.combineLatest(
                        viewModel.inputAmountDriver,
                        viewModel.sourceWalletDriver.map {$0?.token.decimals ?? 0},
                        viewModel.slippageDriver
                    ),
                    resultSelector: {($0, $1.0, $1.1, $1.2)}
                )
                .map {$0?.getIntermediaryToken(inputAmount: $1?.toLamport(decimals: $2) ?? 0, slippage: $3)?.tokenName}
                .drive(routesView.rx.text)
                .disposed(by: disposeBag)
            
            // exchange rate
//            let isExchangeRateEmpty = viewModel.exchangeRateDriver
//                .map {$0 == nil}
//
//            isExchangeRateEmpty
//                .drive(stackView.viewWithTag(1)!.rx.isHidden)
//                .disposed(by: disposeBag)
//            isExchangeRateEmpty
//                .drive(stackView.viewWithTag(2)!.rx.isHidden)
//                .disposed(by: disposeBag)
            
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
            viewModel.slippageDriver
                .map {slippageAttributedText(slippage: $0)}
                .drive(slippageLabel.rx.attributedText)
                .disposed(by: disposeBag)
            
            // swap fees
//            viewModel.isTokenPairValidDriver
//                .map {$0.state != .loaded}
//                .drive(stackView.viewWithTag(4)!.rx.isHidden)
//                .disposed(by: disposeBag)
//            
//            viewModel.isTokenPairValidDriver
//                .map {$0.state != .loaded}
//                .drive(stackView.viewWithTag(5)!.rx.isHidden)
//                .disposed(by: disposeBag)
            
            // error
            viewModel.errorDriver
                .map {$0?.rawValue}
                .drive(errorLabel.rx.text)
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
    }
}
