//
//  SwapToken.SettingsViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/08/2021.
//

import Foundation
import RxCocoa

extension SwapToken {
    class SettingsViewController: SettingsBaseViewController {
        // MARK: - Properties
        private let viewModel: ViewModel
        private var defaultsDisposables = [DefaultsDisposable]()
        private let payingTokenSubject = BehaviorRelay<PayingToken>(value: Defaults.payingToken)
        
        // MARK: - Subviews
        private lazy var separator = UIView.defaultSeparator()
        private var payingTokenSection: UIView?
        private lazy var slippageLabel = UILabel(textSize: 15, weight: .medium)
        private lazy var payingTokenLabel = UILabel(textSize: 15, weight: .medium)
        
        // MARK: - Initializers
        init(viewModel: ViewModel) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func setUp() {
            super.setUp()
            title = L10n.swapSettings
            hideBackButton()
        }
        
        override func bind() {
            super.bind()
            viewModel.output.slippage
                .map {slippageAttributedText(slippage: $0)}
                .drive(slippageLabel.rx.attributedText)
                .disposed(by: disposeBag)
            
            defaultsDisposables.append(Defaults.observe(\.payingToken, handler: { [weak self] update in
                self?.payingTokenSubject.accept(update.newValue ?? .transactionToken)
            }))
            
            Driver.combineLatest(
                viewModel.output.sourceWallet,
                viewModel.output.destinationWallet,
                payingTokenSubject.asDriver()
            )
                .drive(onNext: {[weak self] source, destination, payingToken in
                    self?.setUpPayingTokenLabel(source: source, destination: destination, payingToken: payingToken)
                })
                .disposed(by: disposeBag)
                
        }
        
        override func setUpContent(stackView: UIStackView) {
            stackView.spacing = 12
            
            payingTokenSection = createSectionView(
                title: L10n.payNetworkFeeWith,
                contentView: payingTokenLabel,
                addSeparatorOnTop: false
            )
            
            stackView.addArrangedSubviews {
                createSectionView(
                    title: L10n.slippageSettings,
                    contentView: slippageLabel,
                    addSeparatorOnTop: false
                )
                    .withTag(1)
                    .onTap(self, action: #selector(navigateToSlippageSettingsVC))
                
                separator
                
                payingTokenSection!
            }
        }
        
        // MARK: - Navigation
        @objc private func navigateToSlippageSettingsVC() {
            viewModel.analyticsManager.log(event: .swapSlippageClick)
            
            let vc = SlippageSettingsViewController()
            vc.completion = {[weak self] slippage in
                Defaults.slippage = slippage / 100
                self?.viewModel.input.slippage.accept(slippage / 100)
            }
            show(vc, sender: nil)
        }
        
        // MARK: - Helper
        private func setUpPayingTokenLabel(
            source: Wallet?,
            destination: Wallet?,
            payingToken: PayingToken
        ) {
            let text: String
            var isChoosingEnabled = true
            // if source or destination is native wallet
            if source == nil && destination == nil {
                text = payingToken == .nativeSOL ? "SOL": L10n.transactionToken
            } else if source?.token.isNative == true || destination?.token.isNative == true || payingToken == .nativeSOL
            {
                text = "SOL"
                isChoosingEnabled = false
            } else if let source = source, let destination = destination {
                text = "\(source.token.symbol) + \(destination.token.symbol)"
            } else {
                text = L10n.transactionToken
            }
            payingTokenLabel.text = text
            payingTokenSection?.isUserInteractionEnabled = isChoosingEnabled
        }
    }
}
