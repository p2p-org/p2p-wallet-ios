//
//  SwapToken.SwapFeesViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 14/08/2021.
//

import Foundation
import RxCocoa

protocol SwapTokenSwapFeesViewModelType {
    var feesDriver: Driver<Loadable<[PayingFee]>> {get}
    var sourceWalletDriver: Driver<Wallet?> {get}
    var destinationWalletDriver: Driver<Wallet?> {get}
    var payingTokenDriver: Driver<PayingToken> {get}
    func log(_ event: AnalyticsEvent)
}

extension SerumSwapV1 {
    class SwapFeesViewController: SettingsBaseViewController {
        // MARK: - Properties
        private let viewModel: SwapTokenSwapFeesViewModelType
        private var transactionTokensName: String?
        
        // MARK: - Subviews
        private lazy var feeSections = UIStackView(axis: .vertical, spacing: 20, alignment: .fill, distribution: .fill)
        private lazy var payingTokenSection = UIView.createSectionView(
            title: L10n.payNetworkFeeWith,
            contentView: payingTokenLabel,
            addSeparatorOnTop: false
        )
            .onTap(self, action: #selector(navigateToPayNetworkFeeWithVC))
        private lazy var payingTokenLabel = UILabel(textSize: 15, weight: .medium)
        
        // MARK: - Initializers
        init(viewModel: SwapTokenSwapFeesViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        override func setUp() {
            super.setUp()
            title = L10n.swapFees
            hideBackButton()
        }
        
        override func setUpContent(stackView: UIStackView) {
            stackView.addArrangedSubviews {
                feeSections
//                payingTokenSection // FIXME: Fee relayer
            }
        }
        
        override func bind() {
            super.bind()
            // fees
            viewModel.feesDriver.map {$0.value}
                .drive(onNext: {[weak self] fees in
                    guard let self = self else {return}
                    self.feeSections.arrangedSubviews.forEach {$0.removeFromSuperview()}
                    
                    guard let fees = fees else {return}
                    
                    if let fee = fees.totalFee,
                       let double = fees.totalFee?.lamports.convertToBalance(decimals: fees.totalFee?.token.decimals)
                    {
                        let text = double.toString(maximumFractionDigits: 9) + " " + fee.token.symbol
                        let view = UIView.createSectionView(
                            title: L10n.totalFees,
                            contentView: UILabel(text: text, textSize: 15, weight: .medium),
                            rightView: nil,
                            addSeparatorOnTop: false
                        )
                        self.feeSections.addArrangedSubviews {
                            view
                            UIView.defaultSeparator()
                        }
                    }
                    
                    let sections = fees.map {fee -> [UIView] in
                        [
                            .createSectionView(
                                title: fee.type.headerString,
                                contentView: feeToLabel(fee),
                                rightView: nil,
                                addSeparatorOnTop: false
                            ),
                            .defaultSeparator()
                        ]
                    }
                    self.feeSections.addArrangedSubviews(sections.reduce([], +))
                })
                .disposed(by: disposeBag)
            
            // paying token section
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
            
            // update entire layout
            viewModel.feesDriver
                .drive(onNext: {[weak self] _ in
                    self?.updatePresentationLayout(animated: true)
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
            } else if source?.isNativeSOL == true || destination?.isNativeSOL == true || payingToken == .nativeSOL
            {
                text = "SOL"
            } else {
                text = transactionTokensName ?? L10n.transactionToken
            }
            payingTokenLabel.text = text
            
            let isChoosingDisabled = source?.isNativeSOL == true || destination?.isNativeSOL == true
            payingTokenSection.isUserInteractionEnabled = !isChoosingDisabled
        }
    }
}

private func feeToLabel(_ fee: PayingFee) -> UILabel {
    if let toString = fee.toString {
        return UILabel(text: toString(), textSize: 15, weight: .semibold)
    }
    
    let amount = fee.lamports.convertToBalance(decimals: fee.token.decimals)
    let symbol = fee.token.symbol
    let string = amount.toString(maximumFractionDigits: 9) + " " + symbol
    return UILabel(text: string, textSize: 15, weight: .medium)
}
