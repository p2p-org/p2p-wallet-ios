//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.RecipientView.FeeView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 31/01/2022.
//

import Foundation
import RxCocoa
import RxSwift
import SolanaSwift

extension SendToken {
    final class FeeView: WLFloatingPanelView {
        private let disposeBag = DisposeBag()
        private let coinLogoImageView = CoinLogoImageView(size: 44)

        init(
            solPrice: Double,
            payingWalletDriver: Driver<Wallet?>,
            feeInfoDriver: Driver<Loadable<SendToken.FeeInfo>>
        ) {
            super.init(cornerRadius: 12, contentInset: .init(all: 18))
            stackView.alignment = .center
            stackView.axis = .horizontal
            stackView.spacing = 12
            stackView.addArrangedSubviews {
                coinLogoImageView
                    .setup { imageView in

                        let driver = Driver.combineLatest(
                            payingWalletDriver,
                            feeInfoDriver
                        )

                        driver
                            .map { $0 == nil && $1.value?.hasAvailableWalletToPayFee != false }
                            .drive(imageView.rx.isHidden)
                            .disposed(by: disposeBag)

                        driver
                            .drive(onNext: { [weak imageView] in
                                if $1.value?.hasAvailableWalletToPayFee == false {
                                    imageView?.tokenIcon.image = .squircleNotEnoughFunds
                                } else {
                                    imageView?.setUp(wallet: $0)
                                }
                            })
                            .disposed(by: disposeBag)
                    }
                UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                    UILabel(text: "Account creation fee", textSize: 13, numberOfLines: 0)
                        .setup { label in
                            payingWalletDriver
                                .map { $0 == nil }
                                .drive(label.rx.isHidden)
                                .disposed(by: disposeBag)

                            feeInfoDriver
                                .map { $0.value?.feeAmountInSOL }
                                .map { feeAmountToAttributedString(feeAmount: $0, solPrice: solPrice) }
                                .drive(label.rx.attributedText)
                                .disposed(by: disposeBag)
                        }
                    UILabel(text: "0.509 USDC", textSize: 17, weight: .semibold, numberOfLines: 0)
                        .setup { label in
                            let driver = Driver.combineLatest(
                                payingWalletDriver,
                                feeInfoDriver
                            )
                                .map { payingWallet, feeInfo in
                                    payingWalletToString(
                                        state: feeInfo.state,
                                        value: feeInfo.value,
                                        payingWallet: payingWallet
                                    )
                                }

                            driver.map(\.0)
                                .drive(label.rx.text)
                                .disposed(by: disposeBag)

                            driver.map(\.1)
                                .drive(label.rx.textColor)
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
        amountString = "~\(Defaults.fiat.symbol)" + amount
            .toString(maximumFractionDigits: 9, autoSetMaximumFractionDigits: true)
    }

    let attrString = NSMutableAttributedString()
        .text(title, size: 13, color: .textSecondary)
        .text(" ")
        .text(amountString, size: 13, weight: .semibold)

    return attrString
}

private func payingWalletToString(
    state: LoadableState,
    value: SendToken.FeeInfo?,
    payingWallet: Wallet?
) -> (String?, UIColor) {
    guard let payingWallet = payingWallet else {
        return (L10n.chooseTheTokenToPayFees, .textBlack)
    }
    switch state {
    case .notRequested:
        return (L10n.chooseTheTokenToPayFees, .textBlack)
    case .loading:
        return (L10n.calculatingFees, .textBlack)
    case .loaded:
        guard let value = value else {
            return (L10n.couldNotCalculatingFees, .textBlack)
        }
        if value.hasAvailableWalletToPayFee == false {
            return (L10n.notEnoughFunds, .alert)
        }
        return (value.feeAmount.total.convertToBalance(decimals: payingWallet.token.decimals)
            .toString(maximumFractionDigits: 9, autoSetMaximumFractionDigits: true) + " \(payingWallet.token.symbol)",
            .textBlack)
    case let .error(optional):
        #if DEBUG
            return (optional, .alert)
        #else
            return (L10n.couldNotCalculatingFees, .alert)
        #endif
    }
}
