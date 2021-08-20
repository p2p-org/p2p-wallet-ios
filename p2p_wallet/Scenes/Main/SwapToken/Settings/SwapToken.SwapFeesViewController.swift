//
//  SwapToken.SwapFeesViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/08/2021.
//

import Foundation
import RxCocoa

extension SwapToken {
    class SwapFeesViewController: SettingsBaseViewController {
        // MARK: - Properties
        private let viewModel: ViewModel
        private var defaultsDisposables = [DefaultsDisposable]()
        private let payingTokenSubject = BehaviorRelay<PayingToken>(value: Defaults.payingToken)
        private var transactionTokensName: String?
        
        // MARK: - Subviews
        private lazy var liquidityProviderFeeLabel = UILabel(textSize: 15, weight: .medium)
        private lazy var networkFeeLabel = UILabel(textSize: 15, weight: .medium)
        private lazy var payingTokenLabel = UILabel(textSize: 15, weight: .medium)
        private var payingTokenSection: UIView?
        
        // MARK: - Initializers
        init(viewModel: ViewModel) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func setUp() {
            super.setUp()
            title = L10n.swapFees
            hideBackButton()
        }
        
        override func setUpContent(stackView: UIStackView) {
            payingTokenSection = createSectionView(
                title: L10n.payNetworkFeeWith,
                contentView: payingTokenLabel,
                addSeparatorOnTop: false
            )
                .onTap(self, action: #selector(navigateToPayNetworkFeeWithVC))
            
            stackView.addArrangedSubviews {
                createSectionView(
                    title: L10n.liquidityProviderFee,
                    contentView: liquidityProviderFeeLabel,
                    rightView: nil,
                    addSeparatorOnTop: false
                )
                UIView.defaultSeparator()
                createSectionView(
                    title: L10n.networkFee,
                    contentView: networkFeeLabel,
                    rightView: nil,
                    addSeparatorOnTop: false
                )
                UIView.defaultSeparator()
                payingTokenSection!
            }
        }
        
        override func bind() {
            super.bind()
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
                    if isFeeRelayerEnabled(source: source, destination: destination) {
                        value = lamports.convertToBalance(decimals: source?.token.decimals)
                        symbol = source?.token.symbol ?? ""
                    } else {
                        value = lamports.convertToBalance(decimals: 9)
                    }
                    return "\(value.toString(maximumFractionDigits: 9)) \(symbol)"
                }
                .drive(networkFeeLabel.rx.text)
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
                    var symbols = [String]()
                    if let source = source {symbols.append(source.token.symbol)}
                    if let destination = destination {symbols.append(destination.token.symbol)}
                    self?.transactionTokensName = symbols.isEmpty ? nil: symbols.joined(separator: "+")
                    
                    self?.setUpPayingTokenLabel(source: source, destination: destination, payingToken: payingToken)
                })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        @objc private func navigateToPayNetworkFeeWithVC() {
            viewModel.analyticsManager.log(event: .swapPayNetworkFeeWithClick)
            
            let vc = NetworkFeePayerSettingsViewController(transactionTokenName: transactionTokensName ?? "")
            vc.completion = { method in
                Defaults.payingToken = method
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
            // if source or destination is native wallet
            if source == nil && destination == nil {
                text = payingToken == .nativeSOL ? "SOL": L10n.transactionToken
            } else if source?.token.isNative == true || destination?.token.isNative == true || payingToken == .nativeSOL
            {
                text = "SOL"
            } else {
                text = transactionTokensName ?? L10n.transactionToken
            }
            payingTokenLabel.text = text
            
            let isChoosingDisabled = source?.token.isNative == true || destination?.token.isNative == true
            payingTokenSection?.isUserInteractionEnabled = !isChoosingDisabled
        }
    }
}
