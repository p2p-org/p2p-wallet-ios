//
//  TransactionDetail.AmountSection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 09/03/2022.
//

import BEPureLayout
import Foundation
import RxCocoa
import RxSwift
import UIKit

extension TransactionDetail {
    final class AmountSection: UIStackView {
        private let disposeBag = DisposeBag()
        private let viewModel: TransactionDetailViewModelType

        init(viewModel: TransactionDetailViewModelType) {
            self.viewModel = viewModel
            super.init(frame: .zero)
            set(axis: .vertical, spacing: 18, alignment: .fill, distribution: .fill)
            addArrangedSubviews {
                // Separator
                UIView.defaultSeparator()

                // Amounts
                BEVStack(spacing: 8) {
                    // Swap
                    swapSection()
                        .setup { view in
                            showView(view, onlyWhenTransactionIs: SolanaSDK.SwapTransaction.self)
                        }

                    // Transfer
                    transferSection()
                        .setup { view in
                            showView(view, onlyWhenTransactionIs: SolanaSDK.TransferTransaction.self)
                        }

                    // Fee
                    feesSection()

                    // Total
                    totalSectionForTransfer()
                        .setup { view in
                            showView(view, onlyWhenTransactionIs: SolanaSDK.TransferTransaction.self)
                        }
                }
            }
        }

        @available(*, unavailable)
        required init(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func swapSection() -> BEVStack {
            let swapTransactionDriver = viewModel.parsedTransactionDriver
                .map { $0?.value as? SolanaSDK.SwapTransaction }

            return BEVStack(spacing: 8) {
                BEHStack(spacing: 12) {
                    titleLabel(text: L10n.spent)
                    UILabel(text: "0.00227631 renBTC (~$150)", textSize: 15, textAlignment: .right)
                        .setup { label in
                            swapTransactionDriver
                                .map { [weak self] swapTransaction -> NSAttributedString? in
                                    self?.getAttributedString(
                                        amount: swapTransaction?.sourceAmount,
                                        symbol: swapTransaction?.source?.token.symbol
                                    )
                                }
                                .drive(label.rx.attributedText)
                                .disposed(by: disposeBag)
                        }
                }

                BEHStack(spacing: 12) {
                    titleLabel(text: L10n.received)
                    UILabel(text: "0.00227631 renBTC (~$150)", textSize: 15, textAlignment: .right)
                        .setup { label in
                            swapTransactionDriver
                                .map { [weak self] swapTransaction -> NSAttributedString? in
                                    self?.getAttributedString(
                                        amount: swapTransaction?.destinationAmount,
                                        symbol: swapTransaction?.destination?.token.symbol
                                    )
                                }
                                .drive(label.rx.attributedText)
                                .disposed(by: disposeBag)
                        }
                }
            }
        }

        private func transferSection() -> BEHStack {
            BEHStack(spacing: 12) {
                titleLabel(text: L10n.spent)
                    .setup { label in
                        viewModel.parsedTransactionDriver
                            .map { $0?.amount ?? 0 }
                            .map { $0 > 0 ? L10n.received : L10n.spent }
                            .drive(label.rx.text)
                            .disposed(by: disposeBag)
                    }
                UILabel(text: "0.00227631 renBTC (~$150)", textSize: 15, textAlignment: .right)
                    .setup { label in
                        viewModel.parsedTransactionDriver
                            .map { [weak self] in
                                self?.getAttributedString(amount: abs($0?.amount ?? 0), symbol: $0?.symbol)
                            }
                            .drive(label.rx.attributedText)
                            .disposed(by: disposeBag)
                    }
            }
        }

        private func feesSection() -> BEHStack {
            let feesDriver = viewModel.parsedTransactionDriver
                .map { $0?.fee }

            return BEHStack(spacing: 4, alignment: .top) {
                titleLabel(text: L10n.transferFee)
                    .withContentHuggingPriority(.required, for: .horizontal)
                    .setup { label in
                        viewModel.parsedTransactionDriver
                            .map { $0?.value is SolanaSDK.SwapTransaction }
                            .map { $0 ? L10n.swapFees : L10n.transferFee }
                            .drive(label.rx.text)
                            .disposed(by: disposeBag)
                    }

                BEVStack(spacing: 8) {
                    // deposit
//                    UILabel(text: "0.02 SOL (Deposit)", textSize: 15, textAlignment: .right)
//                        .setup { depositLabel in
//                            feesDriver
//                                .map { [weak self] feeAmount -> NSAttributedString? in
//                                    guard let self = self else {return nil}
//                                    let payingWallet = self.getPayingFeeWallet()
//                                    let amount = feeAmount?.deposit
//                                        .convertToBalance(decimals: payingWallet.token.decimals)
//                                        .toString(maximumFractionDigits: 9)
//
//                                    return NSMutableAttributedString()
//                                        .text(amount + " " + payingWallet.token.symbol + " ", size: 15, color: .textBlack)
//                                        .text("(\(L10n.deposit))", size: 15, color: .textSecondary)
//                                }
//                                .drive(depositLabel.rx.attributedText)
//                                .disposed(by: disposeBag)
//
//                            feesDriver
//                                .map {$0?.deposit ?? 0}
//                                .map {$0 == 0}
//                                .drive(depositLabel.rx.isHidden)
//                                .disposed(by: disposeBag)
//                        }

                    // account creation fee
                    UILabel(
                        text: "0.02 SOL (BTC Account Creation)",
                        textSize: 15,
                        numberOfLines: 2,
                        textAlignment: .right
                    )
                        .setup { accountCreationLabel in
                            feesDriver
                                .map { [weak self] feeAmount -> NSAttributedString? in
                                    guard let self = self else { return nil }
                                    let payingWallet = self.getPayingFeeWallet()
                                    let amount = feeAmount?.accountBalances
                                        .convertToBalance(decimals: payingWallet.token.decimals)

                                    let createdWalletSymbol = self.viewModel.getCreatedAccountSymbol()

                                    return self.getAttributedString(
                                        amount: amount,
                                        symbol: payingWallet.token.symbol,
                                        withFiatValue: false
                                    )
                                        .text(
                                            " (\(L10n.accountCreation(createdWalletSymbol ?? L10n.unknownToken)))",
                                            size: 15,
                                            color: .textSecondary
                                        )
                                }
                                .drive(accountCreationLabel.rx.attributedText)
                                .disposed(by: disposeBag)

                            feesDriver
                                .map { $0?.accountBalances ?? 0 }
                                .map { $0 == 0 }
                                .drive(accountCreationLabel.rx.isHidden)
                                .disposed(by: disposeBag)
                        }

                    // transfer fee
                    BEHStack(spacing: 4) {
                        UILabel(text: "0.02 SOL (Transfer fee)", textSize: 15, textAlignment: .right)
                            .setup { accountCreationLabel in
                                feesDriver
                                    .map { [weak self] feeAmount -> NSAttributedString? in
                                        guard let self = self else { return nil }
                                        let payingWallet = self.getPayingFeeWallet()
                                        let amount = feeAmount?.transaction
                                            .convertToBalance(decimals: payingWallet.token.decimals)

                                        if amount > 0 {
                                            return self.getAttributedString(
                                                amount: amount,
                                                symbol: payingWallet.token.symbol,
                                                withFiatValue: false
                                            )
                                                .text(" (\(L10n.transferFee))", size: 15, color: .textSecondary)
                                        } else {
                                            return NSMutableAttributedString()
                                                .text(L10n.free, size: 15, weight: .semibold)
                                                .text(" (\(L10n.PaidByP2p.org))", size: 15, color: .h34c759)
                                        }
                                    }
                                    .drive(accountCreationLabel.rx.attributedText)
                                    .disposed(by: disposeBag)
                            }
                        UIImageView(width: 21, height: 21, image: .info, tintColor: .h34c759)
                            .setup { infoButton in
                                feesDriver
                                    .map { $0?.transaction != 0 }
                                    .drive(infoButton.rx.isHidden)
                                    .disposed(by: disposeBag)
                            }
                    }
                    .onTap { [weak self] in
                        self?.viewModel.navigate(to: .freeFeeInfo)
                    }

                    // total (for swap only)
                    BEVStack(spacing: 8, alignment: .trailing) {
                        UIView.defaultSeparator()
                            .frame(width: 266)

                        UILabel(text: "0.02 SOL (Transfer fee)", textSize: 15, textAlignment: .right)
                            .setup { totalFeeLabel in
                                feesDriver
                                    .map { [weak self] feeAmount -> NSAttributedString? in
                                        guard let self = self else { return nil }
                                        let payingWallet = self.getPayingFeeWallet()
                                        let totalFee =
                                            ((feeAmount?.transaction ?? 0) + (feeAmount?.accountBalances ?? 0))
                                            .convertToBalance(decimals: payingWallet.token.decimals)

                                        return self.getAttributedString(
                                            amount: totalFee,
                                            symbol: payingWallet.token.symbol,
                                            withFiatValue: false
                                        )
                                            .text(" (\(L10n.totalFee))", size: 15, color: .textSecondary)
                                    }
                                    .drive(totalFeeLabel.rx.attributedText)
                                    .disposed(by: disposeBag)
                            }
                    }
                    .setup { view in
                        showView(view, onlyWhenTransactionIs: SolanaSDK.SwapTransaction.self)
                    }
                }
            }
        }

        private func totalSectionForTransfer() -> BEHStack {
            BEHStack(spacing: 4, alignment: .top) {
                titleLabel(text: L10n.total)
                    .withContentHuggingPriority(.required, for: .horizontal)
                UILabel(text: "0.00227631 renBTC (~$150)", textSize: 15, numberOfLines: 2, textAlignment: .right)
                    .setup { label in
                        viewModel.parsedTransactionDriver
                            .map { [weak self] transaction -> NSAttributedString? in
                                guard let self = self else { return nil }

                                var amount = transaction?.amount ?? 0

                                // received
                                if amount > 0 {
                                    return self.getAttributedString(
                                        amount: amount,
                                        symbol: transaction?.symbol
                                    )
                                }

                                // sent
                                else {
                                    let payingWallet = self.getPayingFeeWallet()
                                    let fees = (transaction?.fee?.total ?? 0)
                                        .convertToBalance(decimals: payingWallet.token.decimals)

                                    amount = abs(amount)

                                    // if the value is of the same token
                                    if payingWallet.token.symbol == transaction?.symbol {
                                        let totalAmount = fees + amount
                                        return self.getAttributedString(
                                            amount: totalAmount,
                                            symbol: payingWallet.token.symbol
                                        )
                                    }

                                    // if the value is from different tokens
                                    else {
                                        // amount spent
                                        let attrStr = self.getAttributedString(
                                            amount: amount,
                                            symbol: transaction?.symbol
                                        )

                                        // fee (if exists)
                                        if fees > 0 {
                                            attrStr.text("\n", size: 15, color: .textBlack)

                                            attrStr.append(
                                                self.getAttributedString(
                                                    amount: fees,
                                                    symbol: payingWallet.token.symbol
                                                )
                                            )
                                        }

                                        return attrStr
                                            .withParagraphStyle(lineSpacing: 8, alignment: .right)
                                    }
                                }
                            }
                            .drive(label.rx.attributedText)
                            .disposed(by: disposeBag)
                    }
            }
        }

        private func getAttributedString(amount: Double?, symbol: String?,
                                         withFiatValue: Bool = true) -> NSMutableAttributedString
        {
            let attStr = NSMutableAttributedString()
                .text(amount.toString(maximumFractionDigits: 9) + " " + symbol, size: 15, color: .textBlack)
            if withFiatValue {
                attStr.text(" ")
                    .text(
                        "(~\(Defaults.fiat.symbol)\(viewModel.getAmountInCurrentFiat(amountInToken: amount, symbol: symbol)?.toString(maximumFractionDigits: 9) ?? "0"))",
                        size: 15,
                        color: .textSecondary
                    )
            }
            return attStr
        }

        private func getPayingFeeWallet() -> Wallet {
            viewModel.getPayingFeeWallet() ?? .nativeSolana(pubkey: nil, lamport: 0)
        }

        private func showView<T: Hashable>(_ view: UIView, onlyWhenTransactionIs _: T.Type) {
            viewModel.parsedTransactionDriver
                .map { $0?.value is T }
                .map { !$0 }
                .drive(view.rx.isHidden)
                .disposed(by: disposeBag)
        }
    }
}

private func titleLabel(text: String, numberOfLines: Int = 2) -> UILabel {
    UILabel(text: text, textSize: 15, textColor: .textSecondary, numberOfLines: numberOfLines)
}
