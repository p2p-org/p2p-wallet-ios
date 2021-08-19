//
//  SerumSwap.RootView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/08/2021.
//

import UIKit
import RxSwift
//import SwiftUI

extension SerumSwap {
    class RootView: ScrollableVStackRootView {
        // MARK: - Constants
        private let disposeBag = DisposeBag()
        
        // MARK: - Properties
        private let viewModel: SerumSwapViewModelType
        
        // MARK: - Subviews
        private lazy var sourceWalletView = WalletView(viewModel: viewModel, type: .source)
        private lazy var reverseButton = UIImageView(width: 44, height: 44, cornerRadius: 12, image: .reverseButton)
            .onTap(self, action: #selector(swapSourceAndDestination))
        private lazy var destinationWalletView = WalletView(viewModel: viewModel, type: .destination)
        
        private lazy var exchangeRateLabel = UILabel(textSize: 15, weight: .medium)
        private lazy var exchangeRateReverseButton = UIImageView(width: 18, height: 18, image: .walletSwap, tintColor: .h8b94a9)
            .padding(.init(all: 3))
            .onTap(self, action: #selector(reverseExchangeRate))
        
        private lazy var slippageLabel = UILabel(textSize: 15, weight: .medium, numberOfLines: 0)
        
        private lazy var errorLabel = UILabel(textSize: 15, weight: .medium, textColor: .alert, numberOfLines: 0)
        
        private lazy var swapButton = WLButton.stepButton(type: .blue, label: L10n.swapNow)
            .onTap(self, action: #selector(authenticateAndSwap))
        
        // MARK: - Initializers
        init(viewModel: SerumSwapViewModelType) {
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
                
                createSectionView(
                    title: L10n.maxPriceSlippage,
                    contentView: slippageLabel
                )
                    .onTap(self, action: #selector(chooseSlippage))
                
                errorLabel
                
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
            // exchange rate
            viewModel.exchangeRateDriver
                .map {exrate -> String? in
                    guard let exrate = exrate else {return nil}
                    var string = exrate.rate.toString(maximumFractionDigits: 9)
                    string += " "
                    string += exrate.to
                    string += " "
                    string += L10n.per
                    string += " "
                    string += exrate.from
                    return string
                }
                .drive(exchangeRateLabel.rx.text)
                .disposed(by: disposeBag)
            
            // slippage
            viewModel.slippageDriver
                .map {slippageAttributedText(slippage: $0 ?? 0)}
                .drive(slippageLabel.rx.attributedText)
                .disposed(by: disposeBag)
            
            // error
            viewModel.errorDriver
                .drive(errorLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.errorDriver
                .map {
                    $0 == nil ||
                    [
                        L10n.insufficientFunds,
                        L10n.amountIsNotValid,
                        L10n.slippageIsnTValid
                    ].contains($0)
                }
                .drive(errorLabel.rx.isHidden)
                .disposed(by: disposeBag)
            
            // button
            viewModel.isSwappableDriver
                .drive(swapButton.rx.isEnabled)
                .disposed(by: disposeBag)
            
            viewModel.slippageDriver
                .map {$0 > .maxSlippage ? L10n.enterANumberLessThanD(Int(Double.maxSlippage * 100)): L10n.swapNow}
                .drive(swapButton.rx.title())
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc private func swapSourceAndDestination() {
            viewModel.swapSourceAndDestination()
        }
        
        @objc private func reverseExchangeRate() {
            viewModel.reverseExchangeRate()
        }
        
        @objc private func authenticateAndSwap() {
            viewModel.authenticateAndSwap()
        }
        
        @objc private func chooseSlippage() {
            viewModel.navigate(to: .chooseSlippage)
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


//@available(iOS 13, *)
//struct SerumSwapRootView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            UIViewPreview {
//                SerumSwap.RootView(viewModel: SerumSwap.ViewModel())
//            }
//            .previewDevice("iPhone SE (2nd generation)")
//        }
//    }
//}
//
