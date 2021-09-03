//
//  NewSwap.SwapFeesViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/08/2021.
//

import Foundation
import RxCocoa

protocol NewSwapSwapFeesViewModelType {
    var feesDriver: Driver<[FeeType: SwapFee]> {get}
    var sourceWalletDriver: Driver<Wallet?> {get}
    var destinationWalletDriver: Driver<Wallet?> {get}
    var payingTokenDriver: Driver<PayingToken> {get}
    func log(_ event: AnalyticsEvent)
}

extension NewSwap {
    class SwapFeesViewController: SettingsBaseViewController {
        // MARK: - Properties
        private let viewModel: NewSwapSwapFeesViewModelType
        private var transactionTokensName: String?
        
        // MARK: - Subviews
        private lazy var liquidityProviderFeeLabel = UILabel(textSize: 15, weight: .medium)
        private lazy var networkFeeLabel = UILabel(textSize: 15, weight: .medium)
        private lazy var payingTokenLabel = UILabel(textSize: 15, weight: .medium)
        private var payingTokenSection: UIView?
        
        // MARK: - Initializers
        init(viewModel: NewSwapSwapFeesViewModelType) {
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
            viewModel.feesDriver.map {$0[.liquidityProvider]}
                .map {fee -> String? in
                    if let toString = fee?.toString {
                        return toString()
                    }
                    
                    guard let amount = fee?.lamports.convertToBalance(decimals: fee?.token.decimals),
                          let symbol = fee?.token.symbol
                    else {return nil}
                    return amount.toString(maximumFractionDigits: 9) + " " + symbol
                }
                .drive(liquidityProviderFeeLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.feesDriver.map {$0[.default]}
                .map {fee -> String? in
                    if let toString = fee?.toString {
                        return toString()
                    }
                    
                    guard let amount = fee?.lamports.convertToBalance(decimals: fee?.token.decimals),
                          let symbol = fee?.token.symbol
                    else {return nil}
                    return amount.toString(maximumFractionDigits: 9) + " " + symbol
                }
                .drive(networkFeeLabel.rx.text)
                .disposed(by: disposeBag)
            
            viewModel.feesDriver
                .drive(onNext: {[weak self] _ in
                    self?.updatePresentationLayout(animated: true)
                })
                .disposed(by: disposeBag)
            
            Driver.combineLatest(
                viewModel.sourceWalletDriver,
                viewModel.destinationWalletDriver,
                viewModel.payingTokenDriver
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
            viewModel.log(.swapPayNetworkFeeWithClick)
            
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
