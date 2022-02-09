//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.RecipientView.FeeView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 31/01/2022.
//

import Foundation
import RxSwift
import RxCocoa
import SolanaSwift

extension SendToken {
    final class FeeView: WLFloatingPanelView {
        private let disposeBag = DisposeBag()
        private let coinLogoImageView = CoinLogoImageView(size: 44)
        
        init(
            solPrice: Double,
            feesDriver: Driver<SolanaSDK.FeeAmount?>,
            payingWalletDriver: Driver<Wallet?>,
            payingWalletStatusDriver: Driver<PayingWalletStatus>
        ) {
            super.init(contentInset: .init(all: 18))
            stackView.alignment = .center
            stackView.axis = .horizontal
            stackView.spacing = 12
            stackView.addArrangedSubviews {
                coinLogoImageView
                    .setup { imageView in
                        payingWalletDriver
                            .map {$0 == nil}
                            .drive(imageView.rx.isHidden)
                            .disposed(by: disposeBag)
                        
                        payingWalletDriver
                            .drive(onNext: {[weak imageView] in imageView?.setUp(wallet: $0)})
                            .disposed(by: disposeBag)
                    }
                UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                    UILabel(text: "Account creation fee", textSize: 13, numberOfLines: 0)
                        .setup { label in
                            feesDriver
                                .map {feeAmountToAttributedString(feeAmount: $0, solPrice: solPrice)}
                                .drive(label.rx.attributedText)
                                .disposed(by: disposeBag)
                        }
                    UILabel(text: "0.509 USDC", textSize: 17, weight: .semibold, numberOfLines: 0)
                        .setup { label in
                            Driver.combineLatest(
                                payingWalletDriver,
                                payingWalletStatusDriver
                            )
                                .map {
                                    payingWalletToString(
                                        payingWallet: $0,
                                        payingWalletStatus: $1
                                    )
                                }
                                .drive(label.rx.text)
                                .disposed(by: disposeBag)
                        }
                }
                UIView.defaultNextArrow()
            }
        }
    }
}

private func feeAmountToAttributedString(feeAmount: SolanaSDK.FeeAmount?, solPrice: Double?) -> NSAttributedString {
    guard let feeAmount = feeAmount else {
        return NSAttributedString()
    }
    
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
        .text("\n")
        .text("Transaction fee: \(feeAmount.transaction) lamports", size: 13, color: .red)
        .text(", ")
        .text("Account creation fee: \(feeAmount.accountBalances) lamports", size: 13, color: .red)
    #endif
    
    return attrString
}

private func payingWalletToString(
    payingWallet: Wallet?,
    payingWalletStatus: SendToken.PayingWalletStatus
) -> String? {
    guard let payingWallet = payingWallet else {
        return L10n.chooseTheTokenToPayFees
    }
    
    switch payingWalletStatus {
    case .loading:
        return L10n.calculatingFees
    case .invalid:
        return L10n.couldNotCalculatingFees
    case .valid(let amount, _):
        return amount.convertToBalance(decimals: payingWallet.token.decimals)
            .toString(maximumFractionDigits: 9, autoSetMaximumFractionDigits: true) + " \(payingWallet.token.symbol)"
            
    }
}
