//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.RecipientView.FeeView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 31/01/2022.
//

import Foundation
import RxSwift
import RxCocoa

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    final class FeeView: WLFloatingPanelView {
        private let viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
        private let disposeBag = DisposeBag()
        private let coinLogoImageView = CoinLogoImageView(size: 44)
        
        init(viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType) {
            self.viewModel = viewModel
            super.init(contentInset: .init(all: 18))
            stackView.alignment = .center
            stackView.axis = .horizontal
            stackView.spacing = 12
            stackView.addArrangedSubviews {
                coinLogoImageView
                    .setup { imageView in
                        self.viewModel.payingWalletDriver
                            .map {$0 == nil}
                            .drive(imageView.rx.isHidden)
                            .disposed(by: disposeBag)
                        
                        self.viewModel.payingWalletDriver
                            .drive(onNext: {[weak imageView] in imageView?.setUp(wallet: $0)})
                            .disposed(by: disposeBag)
                    }
                UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                    UILabel(text: "Account creation fee", textSize: 13, numberOfLines: 0)
                        .setup { label in
                            self.viewModel.feesDriver
                                .map {[weak self] in feeAmountToAttributedString(feeAmount: $0, solPrice: self?.viewModel.getPrice(for: "SOL"))}
                                .drive(label.rx.attributedText)
                                .disposed(by: disposeBag)
                        }
                    UILabel(text: "0.509 USDC", textSize: 17, weight: .semibold, numberOfLines: 0)
                        .setup { label in
                            Driver.combineLatest(
                                viewModel.payingWalletDriver,
                                viewModel.feesDriver
                            )
                                .map {[weak self] in payingWalletToString(payingWallet: $0, feeAmount: $1, tokenPrice: self?.viewModel.getPrice(for: $0?.token.symbol ?? ""), solPrice: self?.viewModel.getPrice(for: "SOL"))}
                                .drive(label.rx.text)
                                .disposed(by: disposeBag)
                        }
                }
                UIView.defaultNextArrow()
            }
            
            onTap { [weak self] in
                self?.viewModel.navigate(to: .selectPayingWallet)
            }
        }
    }
}

private func feeAmountToAttributedString(feeAmount: SolanaSDK.FeeAmount, solPrice: Double?) -> NSAttributedString {
    var titles = [String]()
    if feeAmount.accountBalances > 0 {
        titles.append(L10n.accountCreationFee)
    }
    
    if feeAmount.transaction > 0 {
        titles.append(L10n.transactionFee)
    }
    
    let title = titles.joined(separator: " + ")
    var amount = feeAmount.total.convertToBalance(decimals: 9)
    var amountString = amount.toString(maximumFractionDigits: 9, autoSetMaximumFractionDigits: true) + " SOL"
    if let solPrice = solPrice {
        amount *= solPrice
        amountString = "~\(Defaults.fiat.symbol)" + amount.toString(maximumFractionDigits: 9, autoSetMaximumFractionDigits: true)
    }
    
    let attrString = NSMutableAttributedString()
        .text(title, size: 13, color: .textSecondary)
        .text(" ")
        .text(amountString, size: 13, weight: .semibold)
    
    #if DEBUG
    attrString
        .text(" ")
        .text(feeAmount.total.convertToBalance(decimals: 9).toString(maximumFractionDigits: 9) + " SOL", size: 13, color: .red)
    #endif
    
    return attrString
}

private func payingWalletToString(
    payingWallet: Wallet?,
    feeAmount: SolanaSDK.FeeAmount,
    tokenPrice: Double?,
    solPrice: Double?
) -> String? {
    guard let payingWallet = payingWallet else {
        return L10n.selectTokenToPayFees
    }
    
    var amount = feeAmount.total.convertToBalance(decimals: 9)
    var amountString = amount.toString(maximumFractionDigits: 9, autoSetMaximumFractionDigits: true) + " SOL"
    
    if let solPrice = solPrice,
       let tokenPrice = tokenPrice,
       tokenPrice > 0
    {
        amount = amount * solPrice / tokenPrice
        amountString = amount.toString(maximumFractionDigits: 9, autoSetMaximumFractionDigits: true) + " \(payingWallet.token.symbol)"
    }
    return amountString
}
