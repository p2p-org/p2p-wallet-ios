//
//  ConfirmReceivingBitcoin.ViewController+CreateRenBTC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2022.
//

import KeyAppUI
import RxCocoa

extension ConfirmReceivingBitcoin.ViewController {
    func createRenBTCView() -> BEVStack {
        BEVStack(spacing: 12) {
            ReceiveToken.textBuilder(
                text: (L10n
                    .yourWalletListDoesNotContainARenBTCAccountAndToCreateOne(L10n
                        .youNeedToMakeATransaction) + " " + L10n.youCanChooseWhichCurrencyToPayInBelow)
                    .asMarkdown()
            )

            WLCard {
                BEHStack(spacing: 12, alignment: .center) {
                    CoinLogoImageView(size: 44)
                        .setup { logoView in
                            viewModel.payingWalletDriver
                                .drive(onNext: { [weak logoView] in
                                    logoView?.setUp(wallet: $0)
                                })
                                .disposed(by: disposeBag)
                        }

                    BEVStack(spacing: 4) {
                        UILabel(
                            text: "Account creation fee:",
                            textSize: 13,
                            textColor: .textSecondary,
                            numberOfLines: 0
                        )
                            .setup { label in
                                viewModel.feeInFiatDriver
                                    .map { fee in
                                        NSMutableAttributedString()
                                            .text(L10n.accountCreationFee + ": ", size: 13, color: .textSecondary)
                                            .text(
                                                "~" + Defaults.fiat.symbol + fee.orZero.toString(maximumFractionDigits: 2),
                                                size: 13,
                                                color: .textBlack
                                            )
                                    }
                                    .drive(label.rx.attributedText)
                                    .disposed(by: disposeBag)
                            }
                        UILabel(text: "0.509 USDC", textSize: 17, weight: .semibold)
                            .setup { label in
                                viewModel.feeInTextDriver
                                    .drive(label.rx.text)
                                    .disposed(by: disposeBag)
                            }
                    }

                    UIView.defaultNextArrow()
                }
                .padding(.init(x: 18, y: 14))
            }
            .onTap { [unowned self] in
                self.viewModel.navigateToChoosingWallet()
            }
            .padding(.init(only: .bottom, inset: 12))

            ReceiveToken.textBuilder(
                text: L10n
                    .YouReGoingToCreateAPublicBitcoinAddressThatWillBeValidForTheNext24Hours
                    .youStillCanHoldAndSendBitcoinWithoutRestrictions
                    .asMarkdown()
            )

            ReceiveToken.textBuilder(
                text: L10n
                    .itSAOneTimeAddressSoIfYouSendMultipleTransactionsYourMoneyWillBeLost
                    .asMarkdown()
            )
        }
    }

    func createRenBTCButton() -> UIView {
        TextButton(title: "Pay 0.509 USDC & Continue", style: .primary, size: .large)
            .setup { button in
                Driver.combineLatest(
                    viewModel.totalFeeDriver,
                    viewModel.payingWalletDriver
                )
                    .map { fee, wallet in
                        guard let fee = fee, let wallet = wallet, fee > 0 else {
                            return L10n.continue
                        }
                        return L10n.payAndContinue(fee.toString(maximumFractionDigits: 9) + " " + wallet.token.symbol)
                    }
                    .drive(button.rx.title)
                    .disposed(by: disposeBag)
            }
            .onPressed { [unowned self] _ in
                self.viewModel.createRenBTC()
            }
    }
}
